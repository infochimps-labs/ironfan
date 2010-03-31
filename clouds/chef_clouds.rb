POOL_NAME     = 'chef'
POOL_SETTINGS = Settings[:pools][POOL_NAME.to_sym]
require File.dirname(__FILE__)+'/../settings'
require File.dirname(__FILE__)+'/cloud_aspects'

# If you're west, first run from the shell
#   export EC2_URL=https://us-west-1.ec2.amazonaws.com
# cloud-start -n master -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb
# cloud-start -n slave  -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb
# cloud-ssh -n slave    -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb

# to modify deleteOnTermination:
#   ec2-modify-instance-attribute -v i-0704be6c --block-device-mapping /dev/sda1=vol-e98d2c80::true

pool POOL_NAME do
  cloud :server do
    is_generic_node
    is_chef_client
    is_chef_server
    instances      1..1
    elastic_ip     POOL_SETTINGS[:server][:elastic_ip]
    image_id       AMIS[:canonical_ubuntu_910][:x32_uswest1_ebs]
    user           'ubuntu'
    disable_api_termination true
  end

  cloud :client do
    is_generic_node
    is_chef_client
    is_nfs_client(attributes)
    instances      1..1
    disable_api_termination false
    user_data File.open(File.dirname(__FILE__)+'/../config/initial_user_data_script.sh').read
  end
end
