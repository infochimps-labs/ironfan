require File.dirname(__FILE__)+'/../settings'

# cloud-start -n master -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb
# cloud-start -n slave  -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb
# cloud-ssh -n slave    -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb
# If you're west,
# export EC2_URL=https://us-west-1.ec2.amazonaws.com

POOL_NAME     = 'clyde'
POOL_SETTINGS = Settings[:pools][POOL_NAME.to_sym]

# TODO:
# * auto_shutdown

AMIS = {
  :canonical_ubuntu_910 => {
    :x32_useast1_ebs => 'ami-6743ae0e',
    :x64_useast1_ebs => 'ami-7d43ae14',
    :x32_uswest1_ebs => 'ami-fd5100b8',
    :x64_uswest1_ebs => 'ami-ff5100ba',
    :x32_useast1_s3  => 'ami-bb709dd2',
    :x64_useast1_s3  => 'ami-55739e3c',
    :x32_uswest1_s3  => 'ami-c32e7f86',
    :x64_uswest1_s3  => 'ami-cb2e7f8e',
  },
  :canonical_ubuntu_lucid_daily => {
    :x32_uswest1_ebs  => 'ami-07613042',
  },
  #
  :infochimps_ubuntu_910 => {
    :x32_uswest1_ebs_a  => 'ami-d7613092',
    :x32_uswest1_ebs_b => 'ami-e16130a4',
  },
}

# to modify deleteOnTermination:
#   ec2-modify-instance-attribute -v i-0704be6c --block-device-mapping /dev/sda1=vol-e98d2c80::true

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
      authorize :from_port => 50030, :to_port => 50030
    end
    security_group 'chef' do
      authorize :from_port => 4000,  :to_port => 4000  # chef-server-api
      authorize :from_port => 4040,  :to_port => 4040  # chef-server-webui
      # authorize :from_port => 4369,  :to_port => 4369  # rabbitmq
      # authorize :from_port => 47762, :to_port => 47762 # rabbitmq
      # authorize :from_port => 5672,  :to_port => 5672  # rabbitmq
      # authorize :from_port => 5984,  :to_port => 5984  # couchdb
      # authorize :from_port => 8983,  :to_port => 8983  # chef-solr
    end
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
