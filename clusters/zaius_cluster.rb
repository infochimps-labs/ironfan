$: << File.dirname(__FILE__)+'/../lib'
require 'cluster_chef'

# ACTIVE_FACET = 'master'
# # Chef::Config.from_file(File.expand_path("~/ics/sysadmin/cluster_chef/clusters/foo.rb"))

cluster 'zaius' do |cl|

  cl.role_implication "nfs_server" do |cl|
    cl.cloud.security_group "nfs_server"
    # open_to_group  "nfs_client"
  end

  cl.role_implication "nfs_client" do |cl|
    cl.cloud.security_group "nfs_client"
  end

  cl.role_implication "ssh" do |cl|
    cl.cloud.security_group 'ssh'
  end

  cl.cloud :ec2 do |c|
    c.region                  'us-east-1'
    c.availability_zones      ['us-east-1d']
    c.flavor                  'm1.small'
    c.image_name              'lucid'
    c.backing                 'ebs'
    c.permanent               false
    c.elastic_ip              false
    c.spot_price_fraction     1.0
  end

  cl.facet 'master' do |f|
    f.instances                1
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
end

# puts Chef::Config.configuration.to_yaml

puts Chef::Config.clusters['zaius'].to_hash.to_yaml
puts Chef::Config.clusters['zaius'].facet('master').to_hash.to_yaml

#   has_big_package             settings
#   has_role                    settings, "#{settings[:cluster_name]}_cluster"
#   user_data_is_json_hash      settings
#
#
# end


# knife bootstrap mynode.example.com -r 'role[webserver]','role[production]' --distro debian5.0-apt
