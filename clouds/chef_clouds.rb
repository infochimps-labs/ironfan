POOL_NAME     = 'chef'
require File.dirname(__FILE__)+'/../settings'
POOL_SETTINGS = Settings[:pools][POOL_NAME.to_sym]
require File.dirname(__FILE__)+'/cloud_aspects'

# cloud-start -n master -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb
# cloud-start -n slave  -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb
# cloud-ssh -n slave    -c ~/ics/sysadmin/chef-repo/poolparty/chef_clouds.rb
# If you're on the west coast, to avoid 'ami not found' errors, first run
#   export EC2_URL=https://us-west-1.ec2.amazonaws.com

# to modify deleteOnTermination:
#   ec2-modify-instance-attribute -v i-0704be6c --block-device-mapping /dev/sda1=vol-e98d2c80::true

pool POOL_NAME do
  cloud :server do
    using :ec2
    settings = settings_for_node(POOL_NAME, :server)
    instances           1..1
    is_generic_node     settings
    is_chef_server      settings
    is_chef_client      settings
    is_nfs_server       settings
    image_id            AMIS[:canonical_ubuntu_910][:x32_uswest1_ebs]
    elastic_ip          settings[:elastic_ip]
    user                'ubuntu'
    disable_api_termination true
    puts settings.to_json
  end

  cloud :client do
    using :ec2
    settings = settings_for_node(POOL_NAME, :client)
    instances           1..1
    is_nfs_client       settings
    is_generic_node     settings
    is_chef_client      settings
    image_id            AMIS[:canonical_ubuntu_910][:x32_uswest1_ebs]
    user                'ubuntu'
    disable_api_termination false
    user_data_shell_script = File.open(File.dirname(__FILE__)+'/../config/initial_user_data_script.sh').read
    user_data user_data_shell_script
    puts settings.to_json
  end
end
