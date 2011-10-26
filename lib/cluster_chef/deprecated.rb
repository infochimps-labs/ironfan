module ClusterChef
  class Cluster

    #
    # !! DEPRECATED !!
    #
    # This doesn't really work -- it should be ripped out.
    #
    def use(*clusters)
      warn "The 'use' statement is deprecated #{callers.inspect}"
      clusters.each do |c|
        other_cluster =  ClusterChef.load_cluster(c)
        reverse_merge! other_cluster
      end
      self
    end

  end
end
