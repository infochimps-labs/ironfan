module ClusterChef
  class Cluster

    def discover!
      @aws_instance_hash = {}
      discover_cluster_chef!
      discover_chef_nodes!
      discover_fog_servers!
    end

  protected

    def fog_servers
      @fog_servers ||= ClusterChef.fog_servers.select{|fs| fs.groups.index(cluster_name.to_s) && (fs.state != "terminated") }
    end

    def chef_nodes
      return @chef_nodes if @chef_nodes
      @chef_nodes = []
      Chef::Search::Query.new.search(:node,"cluster_name:#{cluster_name}") do |n|
        @chef_nodes.push(n) unless n.nil? || (n.cluster_name != cluster_name.to_s)
      end
      @chef_nodes
    end

    # Walk the list of chef nodes and
    # * vivify the server,
    # * associate the chef node
    # * if the chef node knows about its instance id, memorize that for lookup
    #   when we discover cloud instances.
    def discover_chef_nodes!
      chef_nodes.each do |chef_node|
        svr = ClusterChef::Server.get(chef_node.cluster_chef_name)
        svr.chef_node = chef_node
        @aws_instance_hash[ chef_node.ec2.instance_id ] = svr if chef_node.ec2.instance_id
      end
    end

    # calling #servers vivifies each facet's ClusterChef::Server instances
    def discover_cluster_chef!
      self.servers
    end

    def discover_fog_servers!
      # If the fog server is tagged with cluster/facet/index, then try to
      # locate the corresponding machine in the cluster def
      # Otherwise, try to get to it through mapping the aws instance id
      # to the chef node name found in the chef node
      fog_servers.each do |fs|
        if fs.tags["cluster"] && fs.tags["facet"] && fs.tags["index"] && fs.tags["cluster"] == cluster_name
          svr = ClusterChef::Server.get([fs.tags["cluster"], fs.tags["facet"], fs.tags["index"]].join('-'))
        elsif @aws_instance_hash[fs.id]
          svr = @aws_instance_hash[fs.id]
        else
          next
        end
        svr.fog_server = fs
      end
    end
  end

end

Chef::Node.class_eval do
  def cluster_chef_name
    node_name
  end
end
