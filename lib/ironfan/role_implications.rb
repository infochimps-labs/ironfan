module Ironfan
  ComputeBuilder.class_eval do

    # organization-wide security group
    role_implication "systemwide" do
      self.cloud.security_group "systemwide" do
      end
    end

    # NFS server allows access from nfs_clients
    role_implication "nfs_server" do
      self.cloud.security_group "nfs_server" do
        authorize_group "nfs_client"
      end
    end

    role_implication "nfs_client" do
      self.cloud.security_group "nfs_client"
    end

    # Opens port 22 to the world
    role_implication "ssh" do
      self.cloud.security_group 'ssh' do
        authorize_port_range 22..22
      end
    end

    # Open the Chef server API port (4000) and the webui (4040)
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
