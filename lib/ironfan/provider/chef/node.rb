module Ironfan
  class Provider
    class ChefServer

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

        def initialize(*args)
          super
          self.adaptee ||= Chef::Node.new
        end

        def to_display(style,values={})
          values["Chef?"] =     adaptee.nil? ? "no" : "yes"
          values
        end

        def save!(machine)
          prepare_from machine
          save
        end

        def create!(machine)
          prepare_from machine

          client = machine[:client]
          unless File.exists?(client.key_filename)
            raise("Cannot create chef node #{name} -- client #{@chef_client} exists but no client key found in #{client.key_filename}.")
          end
          ChefServer.post_rest("nodes", adaptee, :client => client)
        end

        def prepare_from(machine)
          organization =                Chef::Config.organization
          normal[:organization] =       organization unless organization.nil?

          server =                      machine.server
          chef_environment =            server.environment
          run_list.instance_eval        { @run_list_items = server.run_list }
          normal[:cluster_name] =       server.cluster_name
          normal[:facet_name] =         server.facet_name
          normal[:permanent] =          machine.permanent?
          normal[:volumes] =            {}
          machine.stores.each {|v| normal[:volumes][v.name] = v.node}
        end
      end

      class Nodes < Ironfan::Provider::ResourceCollection
        self.item_type =        Node
        self.key_method =       :name

        #
        # Discovery
        #
        def load!(machines)
          query = "name:#{machines.cluster.name}-*"
          ChefServer.search(:node,query) do |raw|
            next if raw.blank?
            node = Node.new
            node.adaptee = raw
            node.owner = self
            self << node
          end
        end

        def correlate!(machines)
          machines.each do |machine|
            if include? machine.server.fullname
              machine.node = self[machine.server.fullname]
              machine.node['volumes'].each do |name,volume|
                machine.store(name).node.merge! volume
              end
              machine.node.users << machine.object_id
            end
          end
        end

        def validate!(machines)
          machines.each do |machine|
            next unless machine.node and not machine[:client]
            machine.bogus << :node_without_client
          end
        end

        #
        # Manipulation
        #
        def create!(machines)
          machines.each do |machine|
            next if machine.node?
            node = Node.new
            node.name         machine.server.fullname
            node.create!      machine
            machine.node =    node
            self <<           node
          end
        end

        def destroy!(machines)
          machines.each do |machine|
            next unless machine.node?
            @clxn.delete(machine.node.name)
            machine.node.destroy
            machine.delete(:node)
          end
        end

        def save!(machines)
          temp = machines.values.select(&:node?)
          temp.each {|machine| machine.node.save! machine }
          machines
        end

      end

    end
  end
end
