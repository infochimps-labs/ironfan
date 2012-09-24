module Ironfan
  class Provider
    class Ec2

      class KeyPair < Ironfan::Provider::Resource
        delegate :_dump, :collection, :collection=, :connection,
            :connection=, :destroy, :fingerprint, :fingerprint=, :identity,
            :identity=, :name, :name=, :new_record?, :public_key,
            :public_key=, :reload, :requires, :requires_one, :save,
            :symbolize_keys, :wait_for, :writable?, :write,
          :to => :adaptee
        field :key_filename,    String,
            :default => ->{ "#{KeyPair.key_dir}/#{name}.pem" }

        def self.shared?()      true;   end
        def self.multiple?()    false;  end
        def self.resource_type()        :key_pair;   end
        def self.expected_ids(computer)   [computer.server.cluster_name];   end

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
          Ironfan.substep(cluster.name, "keypairs")
          Ec2.connection.key_pairs.each do |keypair|
            register keypair unless keypair.blank?
            Chef::Log.debug("Loaded <%-15s %s>" % [handle, keypair.name])
          end
        end

        #
        # Manipulation
        #

        def self.create!(computer)
          name = computer.server.cluster_name
          return if recall? name
          Ironfan.step(name, "creating key pair for #{name}", :blue)
          result = Ec2.connection.create_key_pair(name)
          private_key = result.body["keyMaterial"]
          load!  # Reload to get the native object
          recall(name).private_key = private_key
        end

        #
        # Utility
        #

        def self.key_dir
          return Chef::Config.ec2_key_dir if Chef::Config.ec2_key_dir
          dir = "#{ENV['HOME']}/.chef/credentials/ec2_keys"
          warn "Please set 'ec2_key_dir' in your knife.rb. Will use #{dir} as a default"
          dir
        end
      end

    end
  end
end
