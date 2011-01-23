$: << File.dirname(__FILE__)
require 'cluster_chef'


role_implication "nfs_server" do
  cloud do
    security_group "nfs_server"
    open_to_group  "nfs_client"
  end
end

role_implication "nfs_client" do
  cloud do
    security_group "nfs_client"
  end
end

role_implication "ssh" do
  cloud.security_groups << ['ssh']
end

cluster 'zaius' do

  cloud :aws do |c|
    c.region                  'us-east-1'
    c.availability_zones      ['us-east-1d']
    c.flavor                  'm1.small'
    c.image_name              'lucid'
    c.backing                 'ebs'
    c.permanent               false
    c.elastic_ip              false
    c.spot_price_fraction     1.0
  end

  role                      "base_role"
  role                      "default"
  role                      "ssh" do
    authorize :from_port => 22,  :to_port => 22
  end

  facet 'master' do
    instances                1
    role                     "nfs_server"
    role                     "chef_client"
    has_dynamic_volumes
    role                     "hadoop_namenode"
    role                     "hadoop_secondarynamenode"
    role                     "hadoop_jobtracker"
    recipe                   'hadoop_cluster::format_namenode_once'
    role                     "big_package"

    override_attributes({
        :cluster_size => 3,
      })
  end
end


puts Settings.to_yaml

puts cloud.to_s

#   has_big_package             settings
#   has_role                    settings, "#{settings[:cluster_name]}_cluster"
#   user_data_is_json_hash      settings
#
#
# end


# knife bootstrap mynode.example.com -r 'role[webserver]','role[production]' --distro debian5.0-apt
