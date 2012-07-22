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

    end
  end
end
