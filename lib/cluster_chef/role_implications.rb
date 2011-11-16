module ClusterChef
  ComputeBuilder.class_eval do
    #
    # Some roles imply aspects of the machine that have to exist at creation.
    # For instance, on an ec2 machine you may wish the 'ssh' role to imply a
    # security group explicity opening port 22.
    #
    # @param [String] role_name -- the role that triggers the block
    # @yield block will be instance_eval'd in the object that calls 'role'
    #
    def self.role_implication(name, &block)
      @@role_implications[name] = block
    end

    role_implication "nfs_server" do
      self.cloud.security_group "nfs_server" do
        authorize_group "nfs_client"
      end
    end

    role_implication "nfs_client" do
      self.cloud.security_group "nfs_client"
    end

    role_implication "ssh" do
      self.cloud.security_group 'ssh' do
        authorize_port_range 22..22
      end
    end

    role_implication "chef_server" do
      self.cloud.security_group "chef_server" do
        authorize_port_range 4000..4000  # chef-server-api
        authorize_port_range 4040..4040  # chef-server-webui
      end
    end

    # web server? add the group "web_server" to open the web holes
    role_implication "web_server" do
      self.cloud.security_group("#{cluster_name}-web_server") do
        authorize_port_range  80..80
        authorize_port_range 443..443
      end
    end

    # if you're a redis server, open the port and authorize redis clients in your group to talk to you
    role_implication("redis_server") do
      cluster_name = self.cluster_name # hack: put cluster_name is in scope
      self.cloud.security_group("#{cluster_name}-redis_server") do
        authorize_group("#{cluster_name}-redis_client")
      end
    end

    # redis_clients gain rights to the redis_server
    role_implication("redis_client") do
      self.cloud.security_group("#{cluster_name}-redis_client")
    end

  end
end
