$: << File.dirname(__FILE__)+'/../lib'
require 'cluster_chef'

# ACTIVE_FACET = 'master'
# # Chef::Config.from_file(File.expand_path("~/ics/sysadmin/cluster_chef/clusters/foo.rb"))

# FIXME: delete_on_termination
# FIXME: disable_api_termination
# FIXME: block_device_mapping
# FIXME: instance_initiated_shutdown_behavior
# FIXME: elastic_ip's
#
# FIXME: should we autogenerate the "foo_cluster" and "foo_bar_facet" roles,
#        and dispatch those to the chef server?
# FIXME: EBS volumes?

cluster 'zaius' do |cl|

  cl.cloud :ec2 do |ec2|
    ec2.region                'us-east-1'
    ec2.availability_zones    ['us-east-1d']
    ec2.flavor                'm1.small'
    ec2.image_name            'lucid'
    ec2.backing               'ebs'
    ec2.permanent             false
    ec2.elastic_ip            false
    ec2.spot_price_fraction   1.0
    ec2.user_data :get_name_from => 'broham'
  end

  cl.role                     "base_role"
  cl.role                     "chef_client"
  cl.role                     "ssh"
  cl.role                     "mounts_ebs_volumes"
  cl.role                     "attaches_ebs_volumes"
  cl.role                     "hadoop_s3_keys"
  cl.recipe                   "cluster_chef::dedicated_server_tuning"

  cl.facet 'master' do |f|
    f.instances                3
    f.cloud :ec2 do |ec2|
      f.flavor                 "c1.medium"
    end
    f.role                     "nfs_server"
    f.role                     "hadoop_namenode"
    f.role                     "hadoop_datanode"
    f.role                     "hadoop_secondarynamenode"
    f.role                     "hadoop_jobtracker"
    f.role                     "hadoop_tasktracker"
    f.role                     "big_package"
    f.role                     "hadoop_initial_bootstrap"
    f.chef_attributes({
        :cluster_size => f.instances,
      })
  end

  cl.role_implication "nfs_server" do |cl|
    cl.cloud.security_group "nfs_server" do |g|
      g.authorize_group "nfs_server"
    end
  end

  cl.role_implication "nfs_client" do |cl|
    cl.cloud.security_group "nfs_client"
  end

  cl.role_implication "ssh" do |cl|
    cl.cloud.security_group 'ssh' do |g|
      g.authorize_port_range 22..22
    end
  end

  cl.role_implication "chef_server" do |cl|
    cl.cloud.security_group "chef_server" do |g|
      g.authorize_port_range 4000..4000  # chef-server-api
      g.authorize_port_range 4040..4040  # chef-server-webui
    end
  end

end

# puts Chef::Config.configuration.to_yaml

mycluster = Chef::Config.clusters['zaius']
myfacet   = mycluster.facet('master')
myfacet.resolve!(Chef::Config.clusters['zaius'])
puts myfacet.to_hash_with_cloud.to_yaml
