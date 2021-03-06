# Providers present a lightweight wrapper for various third-party services,
#   such as Chef's node and client APIs, and Amazon's EC2 APIs. This allows
#   Ironfan ask specialized questions (such as whether a given resource
#   matches the one of the Computers that we're handling).
module Ironfan
  class Provider < Builder
    class_attribute :handle

    def self.receive(obj, &block)
      if obj.is_a?(Hash)
        obj = obj.symbolize_keys
        obj[:_type] =
          case obj[:name]
          when :chef        then Chef
          when :ec2         then Ec2
          when :openstack   then OpenStack
          when :static      then Static
          when :vsphere     then Vsphere
          when :virtualbox  then VirtualBox
          when :rds         then Rds
          else raise "Unsupported provider #{obj[:name]}"
          end
      end
      super
    end

    def resources()     self.class.resources;   end
    def self.resources
      raise "missing #{self.class}.resources declaration"
    end

    #
    # Discovery
    #
    def self.load(cluster)
      Ironfan.parallel (resources) do |r|
        type = r.resource_type.to_s
        Ironfan.substep(cluster.name, "loading #{type}s")
        r.load! cluster
        Ironfan.substep(cluster.name, "loaded #{type}s")
      end
    end


    def self.forget!()
      resources.each do |r|
        r.forget!
      end
    end

    def self.validate(computers)
      resources.each {|r| r.validate_resources! computers }
    end

    def self.prepare!(computers)
      resources.each do |r|
        r.prepare!(computers) if r.shared?
      end
    end

    def self.aggregate!(computers)
      resources.each do |r|
        r.aggregate!(computers) if r.shared?
      end
    end

    class Resource < Builder
      @@known = {}
      field             :adaptee,       Whatever
      field             :bogus,         Array,          :default => []
      attr_accessor     :owner
      attr_accessor     :users
      def users()       @users ||= [];  end;

      def bogus?()                      !bogus.empty?;          end

      def self.handle ; name.to_s.gsub(/.*::/,'').to_sym ; end

      def self.receive(obj)
        obj = obj.symbolize_keys if obj.is_a?(Hash)
        super(obj)
      end

      #
      # Flags
      #
      # Non-shared resources live and die with the computer
      def self.shared?()                true;                   end
      # Can multiple instances of this resource be associated with the computer?
      def self.multiple?()              false;                  end

      #
      # Discovery
      #
      def self.load!(*p)                Ironfan.noop(self,__method__,*p);   end
      def self.validate_computer!(*p)   Ironfan.noop(self,__method__,*p);   end
      def self.validate_resources!(*p)  Ironfan.noop(self,__method__,*p);   end

      def on_correlate(*p)              Ironfan.noop(self,__method__,*p);   end

      #
      # Manipulation
      #
      def self.create!(*p)              Ironfan.noop(self,__method__,*p);   end
      def self.save!(*p)                Ironfan.noop(self,__method__,*p);   end
      def self.prepare!(*p)             Ironfan.noop(self,__method__,*p);   end
      def self.aggregate!(*p)           Ironfan.noop(self,__method__,*p);   end
      def self.destroy!(*p)             Ironfan.noop(self,__method__,*p);   end

      #
      # Utilities
      #
      [:shared?, :multiple?, :load!,:validate_computer!, :validate_resources!,
       :create!, :save!, :prepare!, :aggregate!, :destroy!].each do |method_name|
         define_method(method_name) {|*p| self.class.send(method_name,*p) }
       end

      def self.remember(resource,options={})
        index = options[:id] || resource.name
        index += options[:append_id] if options[:append_id]
        Chef::Log.debug("Loaded #{resource}")
        self.known[index] = resource
      end

      # Register and return the (adapted) object with the collection
      def self.register(native)
        result = new(:adaptee => native) or return
        remember result
      end

      def self.recall?(id)
        self.known.include? id
      end

      def self.recall(id=nil)
        return self.known if id.nil?
        self.known[id]
      end

      def self.forget!
        @@known[self.name] = { }
      end

      def self.forget(id)
        self.known.delete(id)
      end

      # Provide a separate namespace in @@known for each subclass
      def self.known
        @@known[self.name] ||= {}
      end

      def self.patiently(name, error_class, options={})
        options[:message]    ||= 'ignoring %s'
        options[:wait_time]  ||= 1
        options[:max_tries]  ||= 10

        success = false
        tries   = 0
        until success or (tries > options[:max_tries]) do
          begin
            result = yield
            success = true # If we made it to this line, the yield didn't raise an exception
          rescue error_class => e
            tries += 1
            if options[:ignore] and options[:ignore].call(e)
              success = true
              Ironfan.substep(name, options[:message] % e.message, options[:display] ? :red : :gray)
            else
              Ironfan.substep(name, options[:message] % e.message, options[:display] ? :red : :gray)
              Ironfan.substep(name, "sleeping #{options[:sleep_time]} second(s) before trying again")
              sleep options[:wait_time]
              result = e
            end
          end
        end

        if success
          return result
        else
          ui.warn("Gave up after #{options[:max_tries]} attempts to execute #{name} code")
          raise result
        end
      end

    end

  end

  class IaasProvider < Provider
    def self.machine_class
      self.const_get(:Machine)
    end

    #
    # Manipulation
    #
    def ensure_prerequisites!(computers)
      # Create all things that aren't machines
      targets = resources.reject {|type| type < IaasProvider::Machine}
      computers.each do |computer|
        targets.each {|r| r.create! computer }
      end
    end

    def save!(computers)
      computers.each do |computer|
        targets.each {|r| r.save! computer }
      end
    end

    class Machine < Resource
      # A Machine lives and dies with its Computer
      def self.shared?()        false;                   end

      # FIXME: users_groups only in 7.4, not 6.3 ... including
      #   this module breaks on our Ubuntu image (with cloud-init 6.3)
      # note that in the sed statement in the bootcmd below,
      #   sed expects some characters to be escaped \(\) etc.
      #   then yaml needs \ inside double-quotes escaped as \x5c
      def self.cloud_init_user_data(computer) 
        return <<EOF
#cloud-config
# The line above is critical - without it cloud-init will not interpret the machine
# user data as a cloud-init script.

# The following logs everything cloud init does to /var/log
output: {all: '| tee -a /var/log/cloud-init-output.log'}

# Set our hostname
manage_etc_hosts: True

fqdn: #{computer.server.fqdn}

cloud_init_modules:
  - bootcmd
  - resizefs
  - set_hostname
  - update_hostname
  - update_etc_hosts
  - ca-certs
  - rsyslog
  - users-groups
  - ssh

bootcmd:
  # note that writefiles is not supported on precise...
  - |
      mkdir -p /etc/chef
      touch /etc/chef/client.pem
      chmod 600 /etc/chef/client.pem
      chown root:root /etc/chef/client.pem
      cat > /etc/chef/client.pem << EOF
#{computer.private_key.split("\n").map {|l| "      "+l}.join("\n")}
      EOF
      domainname #{computer.server.fqdn}
      IP=`curl 169.254.169.254/latest/meta-data/local-ipv4`
      [ -f /etc/cloud/templates/hosts.tmpl ] && sed -i -e "s/127\x5c.0\x5c.1\x5c.1/$IP/" /etc/cloud/templates/hosts.tmpl
      [ -f /etc/cloud/templates/hosts.debian.tmpl ] && sed -i -e "s/127\x5c.0\x5c.1\x5c.1/$IP/" /etc/cloud/templates/hosts.debian.tmpl
      [ -f /etc/cloud/templates/hosts.redhat.tmpl ] && sed -i -e "/::1/d" -e "s/^[0-9]*\x5c.[0-9]*\x5c.[0-9]*\x5c.[0-9]*\x5c( .*fqdn.*\x5c)/$IP\x5c1/" /etc/cloud/templates/hosts.redhat.tmpl

# This is understood to fail gracefully during image creation (before 
# knife cluster bootstrap burninator...) due to Chef not installed yet.
chef:
 install_type: "packages"
 force_install: false
 server_url: #{Chef::Config[:chef_server_url]}
 node_name: #{computer.name}
 initial_attributes:
    chef_server: #{Chef::Config[:chef_server_url]}
    node_name: #{computer.name}
    organization: #{Chef::Config[:organization]}
    realm_name: #{computer.server.realm_name}
    cluster_name: #{computer.server.cluster_name}
    facet_name: #{computer.server.facet_name}
    facet_index: #{computer.server.index}
 validation_name: "no-validator"
 validation_key: |
    We don't need no stinking validators.
EOF
      end

    end
  end
end
