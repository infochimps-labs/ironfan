$: << File.dirname(__FILE__)+'/../lib'
require 'cluster_chef'

# ACTIVE_FACET = 'master'
# # Chef::Config.from_file(File.expand_path("~/ics/sysadmin/cluster_chef/clusters/foo.rb"))

# FIXME: delete_on_termination
# FIXME: disable_api_termination
# FIXME: block_device_mapping
# FIXME: instance_initiated_shutdown_behavior
# FIXME: elastic_ip's

cluster 'zaius' do |cl|

  cl.cloud :ec2 do |c|
    c.region                  'us-east-1'
    c.availability_zones      ['us-east-1d']
    c.flavor                  'm1.small'
    c.image_name              'lucid'
    c.backing                 'ebs'
    c.permanent               false
    c.elastic_ip              false
    c.spot_price_fraction     1.0

    c.security_group "foo"
  end

  cl.facet 'master' do |f|
    f.instances                3
    f.role                     "nfs_server"
    f.role                     "chef_client"
    f.role                     "ssh"
    f.has_dynamic_volumes      true
    f.role                     "hadoop_namenode"
    f.role                     "hadoop_secondarynamenode"
    f.role                     "hadoop_jobtracker"
    f.recipe                   'hadoop_cluster::format_namenode_once'
    f.role                     "big_package"
    f.chef_attributes({
        :cluster_size => 3,
      })
  end

  cl.cloud.user_data :get_name_from => 'broham'

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

end

# puts Chef::Config.configuration.to_yaml

mycluster = Chef::Config.clusters['zaius']
myfacet = mycluster.facet('master')
myfacet.reverse_merge!(Chef::Config.clusters['zaius'])
puts myfacet.to_yaml
