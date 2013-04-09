module Ironfan
  class Provider
    class Vsphere

      class Keypair < Ironfan::Provider::Resource
        delegate :connection, :connection=, :name, :private_key,
          :to => :adaptee
#        delegate :_dump, :collection, :collection=, :connection,
 #           :connection=, :destroy, :fingerprint, :fingerprint=, :identity,
 #           :identity=, :name, :name=, :new_record?, :public_key,
#            :public_key=, :reload, :requires, :requires_one, :save,
#            :symbolize_keys, :wait_for, :writable?, :write,
#          :to => :adaptee

        field :key_filename,    String, :default => ->{ "#{Keypair.key_dir}/#{name}.pem" }

        def self.shared?       ; true     ; end
        def self.multiple?     ; false    ; end
        def self.resource_type ; :keypair ; end

        def self.expected_ids(computer)
          [computer.server.cluster_name]
        end

        def private_key
          puts "pkey"
          File.open(key_filename, "rb").read
        end

        def self.public_key(computer)
          key_filename = "%s/%s.pem" %[key_dir, computer.server.cluster_name]
          key = OpenSSL::PKey::RSA.new(File.open(key_filename, "rb").read)
          data = [ key.to_blob ].pack('m0')
          "#{key.ssh_type} #{data}"
        end
 
        def self.create_private_key(key, name)
          key_filename = "%s/%s.pem" %[key_dir, name]
          File.open(key_filename, "w", 0600){|f| f.print( key.to_s ) }
        end

        def to_s
          "<%-15s %-12s>" % [self.class.handle, name]
        end

        #
        # Manipulation
        #

        def self.prepare!(computers)
          return if computers.empty?
          name = computers.values[0].server.cluster_name
          return if recall? name
          return if File.exists?("%s/%s.pem" %[key_dir, name])
          Ironfan.step(name, "creating key pair for #{name}", :blue)
          Dir.mkdir(key_dir) if !FileTest::directory?(key_dir)
          create_private_key(OpenSSL::PKey::RSA.new(2048), name)
        end

        #
        # Utility
        #

        def self.key_dir
          return Chef::Config.vsphere_key_dir if Chef::Config.vsphere_key_dir
          dir = "#{ENV['HOME']}/.chef/credentials/vshere_keys"
          warn "Please set 'vsphere_key_dir' in your knife.rb. Will use #{dir} as a default"
          dir
        end

      end
    end
  end
end
