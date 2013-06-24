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

        def initialize(*args)
          super
          self.adaptee ||= Chef::ApiClient.new
        end

        def to_s
          "<%-15s %-23s %s>" % [
            self.class.handle, name, key_filename]
        end

        def self.shared?()              false;  end
        def self.multiple?()            false;  end
        def self.resource_type()        :client;                        end
        def self.expected_ids(computer) [computer.server.full_name];     end

        def self.key_dir
          Chef::Config.client_key_dir || "/tmp/#{ENV['USER']}-client_keys"
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
        def self.load!(cluster=nil)
          Chef::ApiClient.list(true).each { |name, raw| client = register(raw) }
          return unless cluster

          # Fallback, for when Solr isn't indexing clients fast enough
          cluster.servers.each do |s|
            next if recall? s.full_name             # Already loaded
            begin; register Chef::ApiClient.load(s.full_name)
            rescue Net::HTTPServerException; end    # Doesn't exist
          end
        end

        #
        # Manipulation
        #
        def self.create!(computer)
          return if computer.client?
          client                = Client.new
          client.name           computer.server.full_name
          client.admin          false

          result                = client.save
          client.private_key    result["private_key"]

          computer[:client]     = client
          remember              client
        end

        def self.destroy!(computer)
          return unless computer.client?
          forget computer.client.name
          computer.client.destroy
          File.delete(computer.client.key_filename)
          computer.delete(:client)
        end
      end

    end
  end
end
