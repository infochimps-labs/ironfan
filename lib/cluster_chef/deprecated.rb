module ClusterChef
  class Cluster

    #
    # !! DEPRECATED !!
    #
    # This doesn't really work -- it should be ripped out.
    #
    def use(*clusters)
      ui.warn "The 'use' statement is deprecated #{callers.inspect}"
      clusters.each do |c|
        other_cluster =  ClusterChef.load_cluster(c)
        reverse_merge! other_cluster
      end
      self
    end

  end

  class Server
    # <b>DEPRECATED:</b> Please use <tt>fullname</tt> instead.
    def chef_node_name name
      ui.warn "[DEPRECATION] `chef_node_name` is deprecated.  Please use `fullname` instead."
      fullname name
    end
  end
end
