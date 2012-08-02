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
            :default => ->{ "#{KeyPairs.key_dir}/#{name}.pem" }

        def private_key
          File.open(key_filename, "rb").read
        end

        def private_key=(body=nil)
          File.open(key_filename, "w", 0600){|f| f.print( body ) }
        end
      end

      class KeyPairs < Ironfan::Provider::ResourceCollection
        self.item_type =        KeyPair

        def self.key_dir
          Chef::Config.ec2_key_dir || "#{ENV['HOME']}/.chef/credentials/ec2_keys"
        end

        def load!(cluster)
          Ec2.connection.key_pairs.each do |kp|
            self << KeyPair.new(:adaptee => kp) unless kp.blank?
          end
        end

        #
        # Manipulation
        #

        def create!(machines)
          name = machines.cluster.name
          return unless self[name].nil?
          Ironfan.step(name, "creating key pair for #{name}", :blue)
          result = Ec2.connection.create_key_pair(name)
          private_key = result.body["keyMaterial"]
          load! machines.cluster
          self[name].private_key = private_key
        end

        #def destroy!(machines)            end

        #def save!(machines)               end

        #
        # Utility
        #
        def key_dir
          if Chef::Config.ec2_key_dir
            return Chef::Config.ec2_key_dir
          else
            dir = "#{ENV['HOME']}/.chef/credentials/ec2_keys"
            warn "Please set 'ec2_key_dir' in your knife.rb. Will use #{dir} as a default"
            dir
          end
        end
      end

    end
  end
end