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

pool POOL_NAME do
  cloud :master do
    using :ec2
    instances          1..1
    image_id           AMIS[:canonical_ubuntu_910][:x32_uswest1_ebs]
    availability_zones ['us-west-1a']
    instance_type      'm1.small'
    elastic_ip         POOL_SETTINGS[:master][:elastic_ip]
    block_device_mapping([
        { :device_name => '/dev/sda1', :ebs_volume_size => 15, :ebs_delete_on_termination => false },
        { :device_name => '/dev/sdc',  :virtual_name => 'ephemeral0' },
      ])

    user               'ubuntu'
    keypair        POOL_NAME, File.join(ENV['HOME'], '.poolparty')
    security_group POOL_NAME
    security_group do
      authorize :from_port => 22,  :to_port => 22
      authorize :from_port => 80,  :to_port => 80
    end
    security_group 'chef-server' do
      authorize :from_port => 4000,  :to_port => 4000  # chef-server-api
      authorize :from_port => 4040,  :to_port => 4040  # chef-server-webui
      authorize :group_name => 'chef-client'
    end
    security_group 'chef-client'
    disable_api_termination              false
    instance_initiated_shutdown_behavior 'stop'
  end

  cloud :slave do
    using :ec2
    instances           1..1
    image_id           AMIS[:canonical_ubuntu_910][:x32_uswest1_ebs]
    # image_id            AMIS[:infochimps_ubuntu_910][:x32_uswest1_ebs_b]
    availability_zones  ['us-west-1a']
    instance_type       'm1.small'
    elastic_ip          '184.72.52.30'
    block_device_mapping([
        { :device_name => '/dev/sda1', :ebs_volume_size => 15, :ebs_delete_on_termination => true },
        { :device_name => '/dev/sdc',  :virtual_name => 'ephemeral0' }, # mount the local storage too
      ])

    user                'ubuntu'
    keypair             POOL_NAME, File.join(ENV['HOME'], '.poolparty')
    security_group      POOL_NAME
    security_group do
      authorize :from_port => 22,  :to_port => 22
      authorize :from_port => 80,  :to_port => 80
    end
    disable_api_termination              false
    instance_initiated_shutdown_behavior 'stop'
  end
end
