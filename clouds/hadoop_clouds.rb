require File.dirname(__FILE__)+'/../settings'
POOL_NAME     = 'clyde'
POOL_SETTINGS = Settings[:pools][POOL_NAME.to_sym]

#
# EBS-backed hadoop cluster in the cloud.
# See the ../README.textile file for usage, etc
#

# TODO:
# * auto_shutdown
#
def is_hadoop_node
  image_id           AMIS[:infochimps_ubuntu_910][:x32_uswest1_ebs_hadoop_b]
  availability_zones ['us-west-1a']
  instance_type      'm1.small'
  block_device_mapping([
      { :device_name => '/dev/sda1', :ebs_volume_size => 15, :ebs_delete_on_termination => false },
      { :device_name => '/dev/sdc',  :virtual_name => 'ephemeral0' },
    ])
  security_group 'chef-client'
  security_group POOL_NAME do
    authorize :group_name => POOL_NAME
  end

  # user           'ubuntu'
  keypair        POOL_NAME, File.join(ENV['HOME'], '.poolparty')
  disable_api_termination              false
  instance_initiated_shutdown_behavior 'stop'
end

pool POOL_NAME do
  cloud :master do
    using :ec2
    is_hadoop_node
    instances          1..1
    elastic_ip         POOL_SETTINGS[:master][:elastic_ip]
    security_group do
      authorize :from_port => 22,  :to_port => 22
      authorize :from_port => 80,  :to_port => 80
    end
    chef_hash = POOL_SETTINGS[:common][:user_data]
    chef_hash.merge!(POOL_SETTINGS[:master][:user_data])
    chef_hash.merge!({:node_name => POOL_NAME+'-master'})
    master_private_ip = POOL_SETTINGS[:master][:elastic_ip]
    nfs_master_ip     = '10.162.143.95'
    chef_hash[:attributes].merge!({
        :hadoop => {
          :jobtracker_hostname => master_private_ip,
          :namenode_hostname   => master_private_ip, },
        :nfs_mounts => [
          ['/home', { :owner => 'root', :device => "#{nfs_master_ip}:/home" } ],
        ],
      })
    user_data  chef_hash.to_json
    puts chef_hash.to_json
  end

  cloud :slave do
    using :ec2
    is_hadoop_node
    instances           1..1
    elastic_ip         POOL_SETTINGS[:slave][:elastic_ip]
    security_group do
      authorize :from_port => 22,  :to_port => 22
      authorize :from_port => 80,  :to_port => 80
    end
    chef_hash = POOL_SETTINGS[:common][:user_data]
    chef_hash.merge!(POOL_SETTINGS[:slave][:user_data])
    chef_hash.merge!({:node_name => POOL_NAME+'-worker'})
    master_private_ip   = pool.clouds['master'].nodes.first.private_ip rescue nil
    master_private_ip ||= POOL_SETTINGS[:master][:elastic_ip]
    nfs_master_ip = '10.162.143.95'
    chef_hash[:attributes].merge!({
        :hadoop => {
          :jobtracker_hostname => master_private_ip,
          :namenode_hostname   => master_private_ip, },
        :nfs_mounts => [
          ['/home', { :owner => 'root', :device => "#{nfs_master_ip}:/home" } ],
        ],
      })
    user_data  chef_hash.to_json
    puts chef_hash.to_json
  end
end
