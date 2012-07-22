module Ironfan
  class Provider
    class ChefServer < Ironfan::Provider

      # 
      # Resources
      #
      class Client < Ironfan::Provider::Resource
        delegate :add_to_index, :admin, :cdb_destroy, :cdb_save, 
            :class_from_file, :couchdb, :couchdb=, :couchdb_id, :couchdb_id=, 
            :couchdb_rev, :couchdb_rev=, :create, :create_keys, 
            :delete_from_index, :destroy, :from_file, :index_id, :index_id=, 
            :index_object_type, :name, :private_key, :public_key, :save, 
            :set_or_return, :to_hash, :validate, :with_indexer_metadata,
          :to => :adaptee

        # matches when client name equals the selector's fullname (strict), or
        #   when name starts with fullname (non-strict)
        def matches_dsl?(selector,options={:strict=>true})
          return false if selector.nil?
          case options[:strict]
          when true;    name == selector.fullname
          when false;   name.match("^#{selector.fullname}")
          end
        end
      end

      class Node < Ironfan::Provider::Resource
        delegate :[], :[]=, :add_to_index, :apply_expansion_attributes,
            :attribute, :attribute=, :attribute?, :automatic_attrs,
            :automatic_attrs=, :cdb_destroy, :cdb_save, :chef_environment,
            :chef_environment=, :chef_server_rest, :class_from_file,
            :construct_attributes, :consume_attributes,
            :consume_external_attrs, :consume_run_list, :cookbook_collection,
            :cookbook_collection=, :couchdb, :couchdb=, :couchdb_id,
            :couchdb_id=, :couchdb_rev, :couchdb_rev=, :create, :default,
            :default_attrs, :default_attrs=, :default_unless,
            :delete_from_index, :destroy, :display_hash, :each,
            :each_attribute, :each_key, :each_value, :expand!, :find_file,
            :from_file, :has_key?, :include_attribute, :index_id, :index_id=,
            :index_object_type, :key?, :keys,
            :load_attribute_by_short_filename, :load_attributes, :name, :node,
            :normal, :normal_attrs, :normal_attrs=, :normal_unless, :override,
            :override_attrs, :override_attrs=, :override_unless, :recipe?,
            :recipe_list, :recipe_list=, :reset_defaults_and_overrides, :role?,
            :run_list, :run_list=, :run_list?, :run_state, :run_state=, :save,
            :set, :set_if_args, :set_or_return, :set_unless, :store, :tags,
            :to_hash, :update_from!, :validate, :with_indexer_metadata,
          :to => :adaptee
        field :client, Ironfan::Provider::ChefServer::Client

        def initialize(config)
          super
          if self.adaptee.nil? and not config[:name].nil?
            self.adaptee = Chef::Node.build(config[:name])
          end
        end

        # matches when node name equals the selector's fullname (strict), or
        #   when name starts with fullname (non-strict)
        def matches_dsl?(selector,options={:strict=>true})
          return false if selector.nil?
          case options[:strict]
          when true;    name == selector.fullname
          when false;   name.match("^#{selector.fullname}")
          end
        end

        def display_values(style,values={})
          values["Chef?"] =     adaptee.nil? ? "no" : "yes"
          values
        end

        def sync!(machine)
          server =                        machine.server
          node.chef_environment =         server.environment
          node.run_list.instance_eval     { @run_list_items = server.run_list }
          organization =                  Chef::Config.organization
          node.normal[:organization] =    organization unless organization.nil?
          node.normal[:cluster_name] =    server.cluster_name
          node.normal[:facet_name] =      server.facet_name
          save
        end
      end

      class Role < Ironfan::Provider::Resource
        delegate :active_run_list_for, :add_to_index, :cdb_destroy, :cdb_save,
          :chef_server_rest, :class_from_file, :couchdb, :couchdb=,
          :couchdb_id, :couchdb_id=, :couchdb_rev, :couchdb_rev=, :create,
          :default_attributes, :delete_from_index, :description, :destroy,
          :env_run_list, :env_run_lists, :environment, :environments,
          :from_file, :index_id, :index_id=, :index_object_type, :name,
          :override_attributes, :recipes, :run_list, :run_list_for, :save,
          :set_or_return, :to_hash, :update_from!, :validate,
          :with_indexer_metadata,
        :to => :adaptee

        def initialize(config)
          super
          if self.adaptee.nil? and not config[:expected].nil?
            expected = config[:expected]
            desc = "Ironfan generated role for #{expected.name}"
            self.adaptee = Chef::Role.new
            self.name                   expected.name
            self.override_attributes    expected.override_attributes
            self.default_attributes     expected.default_attributes
            self.description            desc
          end
          raise "Missing adaptee" if self.adaptee.nil?
          self
        end
      end

      # 
      # Provider
      #
      collection :nodes,      Ironfan::Provider::ChefServer::Node
      collection :clients,    Ironfan::Provider::ChefServer::Client

      def discover!(cluster)
        discover_nodes! cluster
        discover_clients! cluster
      end
      
      def discover_nodes!(cluster)
        return nodes unless nodes.empty?
        Chef::Node.list(true).each_value do |node|
          nodes << Node.new(:adaptee => node) unless node.blank?
        end
        nodes
      end

      def discover_clients!(cluster)
        return clients unless clients.empty?
        Chef::ApiClient.list(true).each_value do |api_client|
          clients << Client.new(:adaptee => api_client) unless api_client.blank?
        end
        clients
      end

      # for all chef nodes that match the cluster,
      #   find a machine that matches and attach,
      #   or make a new machine and mark it :unexpected_node
      # for all chef clients that match
      #     find a machine that matches and attach,
      def correlate(cluster,machines)
        clients_matching(cluster).each do |client|
          match = machines.select {|m| client.matches_dsl? m.server }.first
          if match.nil?
            fake = Ironfan::Broker::Machine.new
            fake.name = client.name
            fake.bogosity = :unexpected_client
            machines << fake
          else
            match[:client] = client
          end
        end
        nodes_matching(cluster).each do |node|
          match = machines.select {|m| node.matches_dsl? m.server }.first
          if match.nil?
            fake = Ironfan::Broker::Machine.new
            fake.name = node.name
            fake.bogosity = :unexpected_node
            machines << fake
          else
            match[:node] = node
          end
        end
        machines
      end
      def nodes_matching(selector)
        nodes.values.select {|n| n.matches_dsl? selector, :strict=>false }
      end
      def clients_matching(selector)
        clients.values.select {|c| c.matches_dsl? selector, :strict=>false }
      end

      def sync!(machines)
        sync_roles! machines
        machines.each do |machine|
          ensure_node machine
          machine[:node].sync! machine
          ensure_client machine
          machine[:client].sync! machine
          raise 'incomplete'
        end
      end
      def sync_roles!(machines)
        defs = []
        machines.each do |m|
          defs << m.server.cluster_role
          defs << m.server.facet_role
        end
        defs = defs.compact.uniq

        defs.each{|d| Role.new(:expected => d).save}
      end
      def ensure_node(machine)
        return machine[:node] if machine.include? :node
        machine[:node] = node(machine.name)
      end
    end

  end
end