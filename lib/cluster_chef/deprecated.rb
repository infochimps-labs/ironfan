module ClusterChef

  class Cluster
    #
    # **DEPRECATED**: This doesn't really work -- use +reverse_merge!+ instead
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
    # **DEPRECATED**: Please use +fullname+ instead.
    def chef_node_name name
      ui.warn "[DEPRECATION] `chef_node_name` is deprecated.  Please use `fullname` instead."
      fullname name
    end
  end

  class Cloud::Ec2
    # **DEPRECATED**: Please use +public_ip+ instead.
    def elastic_ip(*args, &block)
      public_ip(*args, &block)
    end
  end

end
