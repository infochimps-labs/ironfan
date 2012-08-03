module Ironfan
  class Provider
    class ChefServer

      class Client < Ironfan::Provider::Resource
        delegate :add_to_index, :admin, :cdb_destroy, :cdb_save, 
            :class_from_file, :couchdb, :couchdb=, :couchdb_id, :couchdb_id=, 
            :couchdb_rev, :couchdb_rev=, :create, :create_keys, 
            :delete_from_index, :destroy, :from_file, :index_id, :index_id=, 
            :index_object_type, :name, :public_key, :save, :set_or_return, 
            :to_hash, :validate, :with_indexer_metadata,
          :to => :adaptee
        field :key_filename,    String,
            :default => ->{ "#{Client.key_dir}/client-#{name}.pem" }

        def self.key_dir
          Chef::Config.client_key_dir || "/tmp/#{ENV['USER']}-client_keys"
        end

        def initialize(*args)
          super
          self.adaptee ||= Chef::ApiClient.new
        end

        def create!
          params = {:name => self.name, :admin => self.admin, :private_key => true }
          result = ChefServer.post_rest("clients", params)
          self.private_key(result["private_key"])
        end

        def private_key(body=nil)
          if body.nil?
            body = File.open(key_filename, "rb").read
          else
            File.open(key_filename, "w", 0600){|f| f.print( body ) }
          end
          adaptee.private_key(body)
        end

        #
        # Discovery
        #
        def self.load!(computers)
          name = computers.cluster.name
          nameq = "name:#{name}-* OR clientname:#{name}-*"
          ChefServer.search(:client, nameq) do |client|
            register client unless client.blank?
          end
        end

        def self.correlate!(computers)
          # FIXME: Computers.each
          computers.each do |computer|
            if recall? computer.server.fullname
              computer[:client] = recall computer.server.fullname
              computer[:client].users << computer.object_id
            end
          end
        end

        # 
        # Manipulation
        #
        def self.create!(computers)
          # FIXME: Computers.each
          computers.each do |computer|
            next if computer.client?
            client = Client.new
            client.name         computer.server.fullname
            client.admin        false
            client.create!
            computer[:client] =  client
            remember             client
          end
        end

        def self.destroy!(computers)
          # FIXME: Computers.each
          computers.each do |computer|
            next unless computer.client?
            forget computer.client.name
            computer.client.destroy
            File.delete(computer.client.key_filename)
            computer.delete(:client)
          end
        end

        # def self.save!(computers)               end
      end

    end
  end
end
