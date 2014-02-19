module Ironfan
  class Provider
    class OpenStack

      class Keypair < Ironfan::Provider::Resource
        delegate :_dump, :collection, :collection=, :connection,
            :connection=, :destroy, :fingerprint, :fingerprint=, :identity,
            :identity=, :name, :name=, :new_record?, :public_key,
            :public_key=, :reload, :requires, :requires_one, :save,
            :symbolize_keys, :wait_for, :writable?, :write,
          :to => :adaptee

        field :key_filename,    String, :default => ->{ "#{Keypair.key_dir}/#{name}.pem" }

        def self.shared?       ; true     ; end
        def self.multiple?     ; false    ; end
        def self.resource_type ; :keypair ; end
        def self.expected_ids(computer)
          [computer.server.cluster_name]
        end

        def private_key
          File.open(key_filename, "rb").read
        end

        def private_key=(body=nil)
          File.open(key_filename, "w", 0600){|f| f.print( body ) }
        end

        def to_s
          "<%-15s %-12s>" % [self.class.handle, name]
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          OpenStack.connection.key_pairs.each do |keypair|
            register keypair unless keypair.blank?
          end
        end

        def receive_adaptee(obj)
          obj = Openstack.connection.key_pairs.new(obj) if obj.is_a?(Hash)
          super
        end

        #
        # Manipulation
        #

        def self.prepare!(computers)
          return if computers.empty?
          name = computers.values[0].server.cluster_name
          return if recall? name
          Ironfan.step(name, "creating key pair for #{name}", :blue)
          result = OpenStack.connection.create_key_pair(name)
          private_key = result.body["keypair"]["private_key"]
          load!  # Reload to get the native object
          recall(name).private_key = private_key
        end

        #
        # Utility
        #

        def self.key_dir
          return Chef::Config.openstack_key_dir if Chef::Config.openstack_key_dir
          dir = "#{ENV['HOME']}/.chef/credentials/openstack_keys"
          warn "Please set 'openstack_key_dir' in your knife.rb. Will use #{dir} as a default"
          dir
        end

      end

    end
  end
end
