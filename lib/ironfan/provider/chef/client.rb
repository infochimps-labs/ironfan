module Ironfan
  class Provider
    class ChefServer

      class Client < Ironfan::Provider::Resource
        delegate :add_to_index, :admin, :cdb_destroy, :cdb_save, 
            :class_from_file, :couchdb, :couchdb=, :couchdb_id, :couchdb_id=, 
            :couchdb_rev, :couchdb_rev=, :create, :create_keys, 
            :delete_from_index, :destroy, :from_file, :index_id, :index_id=, 
            :index_object_type, :name, :private_key, :public_key, :save, 
            :set_or_return, :to_hash, :validate, :with_indexer_metadata,
          :to => :adaptee
        field :key_filename,    String,
            :default => ->{ "#{Clients.key_dir}/client-#{name}.pem" }

        def initialize(*args)
          super
          self.adaptee ||= Chef::ApiClient.new
        end

        def create!
          params = {:name => self.name, :admin => self.admin, :private_key => true }
          result = ChefServer.rest_connect.post_rest("clients", params)
          self.private_key(result["private_key"])
        end

        def private_key(body=nil)
          File.open(key_filename, "w", 0600){|f| f.print( body ) } unless body.nil?
          adaptee.private_key(body)
        end
      end

      class Clients < Ironfan::Provider::ResourceCollection
        self.item_type =        Client
        self.key_method =       :name

        def self.key_dir
          Chef::Config.client_key_dir || "/tmp/#{ENV['USER']}-client_keys"
        end
        #
        # Discovery
        #
        def load!(machines)
          name = machines.cluster.name
          nameq = "name:#{name}-* OR clientname:#{name}-*"
          Chef::Search::Query.new.search(:client, nameq) do |client|
            attrs = {:adaptee => client, :owner => self}
            self << Client.new(attrs) unless client.blank?
          end
        end

        def correlate!(machines)
          machines.each do |machine|
            if include? machine.server.fullname
              machine[:client] = self[machine.server.fullname]
              machine[:client].users << machine.object_id
            end
          end
        end

        # 
        # Manipulation
        #
        def create!(machines)
          machines.each do |machine|
            next if machine.client?
            client = Client.new
            client.name         machine.server.fullname
            client.admin        false
            client.create!
            machine[:client] =  client
            self <<             client
          end
        end

        def destroy!(machines)
          machines.each do |machine|
            next unless machine.client?
            @clxn.delete(machine.client.name)
            machine.client.destroy
          end
        end

        # def save!(machines)               end
      end

    end
  end
end
