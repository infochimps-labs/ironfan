require 'chef/resource'
require 'chef/provider'

class Chef
  class Resource
    class NodeMetadata < Chef::Resource

      def initialize(node, run_context=nil)
        super(node, run_context)
        @node          = node
        @resource_name = :update_node
        @action        = "nothing"
        @allowed_actions.push(:save)
      end
    end
  end

  class Provider
    class NodeMetadata < Chef::Provider
      def action_save
        save_node!(@new_resource.name)
        @new_resource.updated_by_last_action(false)
      end

      def load_current_resource
        true
      end
    end
  end
end
