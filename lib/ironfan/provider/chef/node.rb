module Ironfan
  class Provider
    class ChefServer

      class Node < Ironfan::Provider::Resource
        delegate :[], :[]=, :add_to_index, :apply_expansion_attributes,
            :attribute, :attribute=, :attribute?, :automatic_attrs,
            :automatic_attrs=, :cdb_destroy, :cdb_save, :chef_environment,
            :chef_server_rest, :class_from_file,
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
            :set, :set_if_args, :set_or_return, :set_unless, :drive, :tags,
            :to_hash, :update_from!, :validate, :with_indexer_metadata,
          :to => :adaptee

        def initialize(*args)
          super
          self.adaptee ||= Chef::Node.new
        end

        def to_s
          "<%-15s %-23s %s>" % [
            self.class.handle, name, run_list]
        end

        def self.shared?()              false;  end
        def self.multiple?()            false;  end
#         def self.resource_type()        self;   end
        def self.resource_type()        :node;   end
        def self.expected_ids(computer) [computer.server.full_name];   end

        def to_display(style,values={})
          values["Chef?"] =     adaptee.nil? ? "no" : "yes"
          values
        end

        def save!(computer)
          prepare_from computer
          save
        end

        def create!(computer)
          prepare_from computer

          client = computer[:client]
          unless File.exists?(client.key_filename)
            raise("Cannot create chef node #{name} -- client #{@chef_client} exists but no client key found in #{client.key_filename}.")
          end
          ChefServer.post_rest("nodes", adaptee, :client => client)
        end

        def prepare_from(computer)
          organization =                Chef::Config.organization
          normal[:organization] =       organization unless organization.nil?
          server =                      computer.server
          chef_environment(server.environment.to_s)
          run_list.instance_eval        { @run_list_items = server.run_list }
          normal[:realm_name] =         server.realm_name
          normal[:cluster_name] =       server.cluster_name
          normal[:facet_name] =         server.facet_name
          normal[:permanent] =          computer.permanent?
          normal[:volumes] =            {}
          computer.drives.each {|d| normal[:volumes][d.name] = d.node}
        end

        def announce_state state
          set[:state] = state
          save
        end

        def conterminous_with_machine?
          true
        end

        #
        # Discovery
        #
        def self.load!(cluster = nil)
          query = cluster && "name:#{cluster.realm_name}-*"
          ChefServer.search(:node, query) do |raw|
            next unless raw.present?
            node = register(raw)
          end
        end

        def on_correlate(computer)
          return unless self['volumes']
          self['volumes'].each do |name,volume|
            computer.drive(name).node.merge! volume
          end
        end

        def self.validate_computer!(computer)
          return unless computer.node and not computer[:client]
          computer.node.bogus << :node_without_client
        end

        #
        # Manipulation
        #
        def self.create!(computer)
          return if computer.node?
          node = Node.new
          node.name           computer.server.full_name
          node.create!        computer
          computer.node =     node
          remember            node
        end

        def self.destroy!(computer)
          return unless computer.node?
          forget computer.node.name
          computer.node.destroy
          computer.delete(:node)
        end

        def self.save!(computer)
          return unless computer.node?
          computer.node.save! computer
        end

      end

    end
  end
end
