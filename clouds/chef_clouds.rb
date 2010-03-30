require File.dirname(__FILE__)+'/../settings'
POOL_NAME     = 'chef'
POOL_SETTINGS = Settings[:pools][POOL_NAME.to_sym]

# If you're west, first run from the shell
#   export EC2_URL=https://us-west-1.ec2.amazonaws.com
# cloud-start -n master -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb
# cloud-start -n slave  -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb
# cloud-ssh -n slave    -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb

# to modify deleteOnTermination:
#   ec2-modify-instance-attribute -v i-0704be6c --block-device-mapping /dev/sda1=vol-e98d2c80::true

pool POOL_NAME do
  cloud :server do
    using :ec2
    instances          1..1
    image_id           AMIS[:canonical_ubuntu_910][:x32_uswest1_ebs]
    availability_zones ['us-west-1a']
    instance_type      'm1.small'
    elastic_ip         POOL_SETTINGS[:server][:elastic_ip]
    block_device_mapping([
        { :device_name => '/dev/sda1', :ebs_volume_size => 15, :ebs_delete_on_termination => false },
        { :device_name => '/dev/sdc',  :virtual_name => 'ephemeral0' },
      ])

    user               'ubuntu'
    keypair        POOL_NAME, File.join(ENV['HOME'], '.poolparty')
    security_group do #chef-server
      authorize :from_port => 22,  :to_port => 22
      authorize :from_port => 80,  :to_port => 80
      authorize :from_port => 4000,  :to_port => 4000  # chef-server-api
      authorize :from_port => 4040,  :to_port => 4040  # chef-server-webui
      authorize :group_name => 'chef'
    end
    security_group POOL_NAME do
      authorize :group_name => POOL_NAME
    end
    security_group 'clyde' do
      authorize :group_name => 'clyde'
    end
    security_group 'chef-client'
    disable_api_termination              false
    instance_initiated_shutdown_behavior 'stop'
  end
end
