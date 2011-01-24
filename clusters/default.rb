
ClusterChef.cluster 'defaults' do
  cloud :ec2 do
    region              'us-east-1'
    availability_zones  ['us-east-1d']
    flavor              'm1.small'
    image_name          'mrflip-maverick-client'
    backing             'ebs'
    permanent           false
    elastic_ip          false
    user_data           :get_name_from => 'broham'
    spot_price_fraction nil
    bootstrap_distro    'ubuntu10.04-cluster_chef'
  end

  role_implication "hadoop_namenode" do
    cloud.security_group 'hadoop_namenode' do
      authorize_port_range 80..80
    end
  end

  role_implication "nfs_server" do
    cloud.security_group "nfs_server" do
      authorize_group "nfs_client"
    end
  end

  role_implication "nfs_client" do
    cloud.security_group "nfs_client"
  end

  role_implication "ssh" do
    cloud.security_group 'ssh' do
      authorize_port_range 22..22
    end
  end

  role_implication "chef_server" do
    cloud.security_group "chef_server" do
      authorize_port_range 4000..4000  # chef-server-api
      authorize_port_range 4040..4040  # chef-server-webui
    end
  end

  role                  "base_role"
  role                  "chef_client"
  role                  "ssh"
end
