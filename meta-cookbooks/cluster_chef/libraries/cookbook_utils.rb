
module ClusterChef
  module CookbookUtils

    def self.node_changed!
      p [self.object_id, @node_changed]
      @node_changed = true
    end
    def node_changed! ; ClusterChef::CookbookUtils.node_changed! ; end

    def self.node_changed?
      p [self.object_id, @node_changed]
      !! @node_changed
    end
    def node_changed? ; ClusterChef::CookbookUtils.node_changed? ; end

    class ::Chef ; MIN_VERSION_FOR_SAVE = "0.8" ; end

    #
    # Save the node, unless we're in chef-solo mode (or an ancient version)
    #
    def save_node!
      p [self.object_id, @node_changed]
      Chef::Log.info('Saving Node!!!!')

      return unless node_changed?
      # taken from ebs_volume cookbook
      if Chef::VERSION >= Chef::MIN_VERSION_FOR_SAVE
        if not Chef::Config.solo
          node.save
        else
          Chef::Log.warn("Skipping node save since we are running under chef-solo.  Node attributes will not be persisted.")
        end
      else
        Chef::Log.warn("Skipping node save because saving a node in a recipe prior to version #{Chef::MIN_VERSION_FOR_SAVE} isn't valid");
      end
    end

  end
end


class Chef::ResourceDefinition ; include ClusterChef::CookbookUtils ; end
class Chef::Resource           ; include ClusterChef::CookbookUtils ; end
class Chef::Recipe             ; include ClusterChef::CookbookUtils ; end
class Chef::Provider::NodeMetadata ; include ClusterChef::CookbookUtils ; end
