module ClusterChef
  ComputeBuilder.class_eval do
    def new_chef_role(role_name, cluster, facet=nil)
      chef_role = Chef::Role.new
      chef_role.name        role_name
      chef_role.description "ClusterChef generated role for #{[cluster_name, facet_name].compact.join('-')}" unless chef_role.description
      chef_role.instance_eval{ @cluster = cluster; @facet = facet; }
      @chef_roles << chef_role
      chef_role
    end
  end


  #
  # ClusterChef::Server methods that handle chef actions
  #
  Server.class_eval do

    def chef_set_runlist
      chef_node.run_list = Chef::RunList.new(*@settings[:run_list])
    end

    def chef_set_attributes
      chef_attributes.each_pair do |key,value|
        next if key == :run_list
        chef_node.normal[key] = value
      end
    end

    def chef_client
      # return @chef_client unless @chef_client.nil?
      # begin
      #   @chef_client = Chef::Client.load( fullname )
      # rescue Net::HTTPServerException => e
      #   raise unless e.response.code == '404'
      #   @chef_client = false
      # end
      false
    end

    # true if chef node is created and discovered
    def chef_node?
      !! @chef_node
    end

    def chef_node
      return @chef_node unless @chef_node.nil?
      begin
        @chef_node = Chef::Node.load( fullname )
      rescue Net::HTTPServerException => e
        raise unless e.response.code == '404'
        @chef_node = false
      end
    end

    def ensure_chef_client
      chef_client
    end

    def ensure_chef_node
      chef_node
    end
  end
end
