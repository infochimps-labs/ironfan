require 'chef/resource'
require 'chef/provider'

class Chef
  class Resource
    class NodeMetadata < Chef::Resource

      def initialize(name, run_context=nil)
        super(name, run_context)
        @resource_name = :update_node
        @action        = "nothing"
        @allowed_actions.push(:save)
      end
    end
  end

  class Provider
    class NodeMetadata
      def action_save
        save_node!
      end

      def load_current_resource
        @current_resource = Chef::Resource::NodeMetadata.new('node')
      end
    end
  end
end
