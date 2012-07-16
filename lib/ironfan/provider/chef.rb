module Ironfan
  module Provider
    module ChefServer

      # 
      # Resources
      #
      class Node < Ironfan::Provider::Resource
        delegate :[], :[]=, :add_to_index, :apply_expansion_attributes, 
            :attribute, :attribute=, :attribute?, :automatic_attrs, 
            :automatic_attrs=, :cdb_destroy, :cdb_save, :chef_environment, 
            :chef_server_rest, :class_from_file, :construct_attributes, 
            :consume_attributes, :consume_external_attrs, :consume_run_list, 
            :cookbook_collection, :cookbook_collection=, :couchdb, :couchdb=, 
            :couchdb_id, :couchdb_id=, :couchdb_rev, :couchdb_rev=, :create, 
            :default, :default_attrs, :default_attrs=, :default_unless, 
            :delete_from_index, :destroy, :display_hash, :each, :each_attribute, 
            :each_key, :each_value, :expand!, :find_file, :from_file, :has_key?, 
            :include_attribute, :index_id, :index_id=, :index_object_type, :key?, 
            :keys, :load_attribute_by_short_filename, :load_attributes, 
            :method_missing, :name, :node, :normal, :normal_attrs, 
            :normal_attrs=, :normal_unless, :override, :override_attrs, 
            :override_attrs=, :override_unless, :recipe?, :recipe_list, 
            :recipe_list=, :reset_defaults_and_overrides, :role?, :run_list, 
            :run_list=, :run_list?, :run_state, :run_state=, :save, :set, 
            :set_if_args, :set_or_return, :set_unless, :store, :tags, :to_hash, 
            :update_from!, :validate, :with_indexer_metadata,
          :to => :adaptee

        def matches?(machine)
          machine.expected.full_name == name 
        end

        def display_values(style,values={})
          values["Chef?"] =     adaptee.nil? ? "no" : "yes"
          values
        end

      end

      class Role < Ironfan::Provider::Resource
      end

      class Client < Ironfan::Provider::Resource
        field    :adaptee,       Whatever
        delegate :name,         :to => :adaptee
      end

      # 
      # Connection
      #
      class Connection < Ironfan::Provider::Connection
        collection :nodes,      Ironfan::Provider::ChefServer::Node
        collection :clients,    Ironfan::Provider::ChefServer::Client

        def discover!(cluster) 
          discover_nodes! cluster
          discover_clients! cluster
        end
        
        def discover_nodes!(cluster)
          return nodes unless nodes.empty?
          Chef::Search::Query.new.search(:node,"cluster_name:#{cluster.name}") do |node|
            nodes << Node.new(:adaptee => node) unless node.blank?
          end
          nodes
        end
        
        def find_node(server)
          nodes[server.full_name]
        end
        
        def discover_clients!(cluster)
          return clients unless clients.empty?
          # Oh for fuck's sake -- the key used to index clients changed from
          # 'clientname' in 0.10.4-and-prev to 'name' in 0.10.8. Rather than index
          # both 'clientname' and 'name', they switched it -- so we have to fall
          # back.  FIXME: While the Opscode platform is 0.10.4 I have clientname
          # first (sorry, people of the future). When it switches to 0.10.8 we'll
          # reverse them (suck it people of the past).
          api_clients = _find_clients(cluster.name,"clientname")
          api_clients = _find_clients(cluster.name) if api_clients.blank?
          api_clients.each do |api_client|
            # Sometimes the server returns nil results on recently-expired clients
            next if api_client.nil?
            # Return values from Chef::Search seem to be inconsistent across chef
            # versions (sometimes a hash, sometimes an object)
            api_client = Chef::ApiClient.json_create(api_client) unless api_client.is_a?(Chef::ApiClient)
            clients << Client.new(:adaptee => api_client)
          end
          clients
        end
        def _find_clients(name,key="name")
          Chef::Search::Query.new.search(:client,"#{key}:#{name}-*")[0].compact
        end
      end

    end
  end
end