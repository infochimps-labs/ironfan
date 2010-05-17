POOL_NAME     = 'kong'
require File.dirname(__FILE__)+'/cloud_aspects'

# Example usage (starts the chef server, then logs in to it)
#
#   cloud-start -n server -c clouds/chef_clouds.rb
#
# If you're using the west coast availability zone, to avoid 'ami not found' errors, first run
#
#   export EC2_URL=https://us-west-1.ec2.amazonaws.com
#
# The bootstrap clouds take a long time to run: consider using a pre-burned AMI
# To pass the time (and to debug), run:
#
#   tail -n1000 -f /tmp/user_data-progress.log /var/log/dpkg.log /etc/sv/chef-client/log/main/current
#

pool POOL_NAME do

  #
  # Creates a chef server AMI from scratch.
  #
  cloud :bootstrap_server do
    using :ec2
    settings = settings_for_node(POOL_NAME, :bootstrap_server)
    instances                   1..1
    is_generic_node             settings
    sends_aws_keys              settings
    is_chef_server              settings
    is_chef_client              settings
    mounts_ebs_volumes          settings
    is_nfs_server               settings
    is_spot_priced              settings
    user                        'ubuntu'
    security_group              POOL_NAME
    user_data                   bootstrap_chef_script('bootstrap_chef_server', settings)
  end


  #
  # Use this to create a generic chef client
  #
  cloud :bootstrap_client do
    using :ec2
    settings = settings_for_node(POOL_NAME, :bootstrap_client)
    instances                   1..1
    is_nfs_client               settings
    is_generic_node             settings
    sends_aws_keys              settings
    is_chef_client              settings
    #
    attaches_ebs_volumes        settings
    mounts_ebs_volumes          settings
    has_big_package             settings
    #
    is_spot_priced              settings
    user                        'ubuntu'
    user_data                   bootstrap_chef_script('bootstrap_chef_client', settings)
  end

  #
  # Use this to create a generic 64-bit chef client
  #
  cloud :bootstrap_client64 do
    using :ec2
    settings = settings_for_node(POOL_NAME, :bootstrap_client64)
    instances                   1..1
    is_nfs_client               settings
    is_generic_node             settings
    sends_aws_keys              settings
    is_chef_client              settings
    #
    attaches_ebs_volumes        settings
    mounts_ebs_volumes          settings
    has_big_package             settings
    #
    is_spot_priced              settings
    user                        'ubuntu'
    user_data                   bootstrap_chef_script('bootstrap_chef_client', settings)
  end

  #
  # This must be run on a pre-bootstrapped chef server AMI
  #
  cloud :server do
    using :ec2
    settings = settings_for_node(POOL_NAME, :server)
    instances                   1..1
    is_generic_node             settings
    sends_aws_keys              settings
    is_chef_server              settings
    is_chef_client              settings
    mounts_ebs_volumes          settings
    is_nfs_server               settings
    is_spot_priced              settings
    user                        'ubuntu'
    security_group              POOL_NAME
    user_data                   bootstrap_chef_script('run_chef_server', settings)
  end

  #
  # This must be run on a pre-bootstrapped chef client AMI
  # expecting a JSON hash of settings in the user-data
  #
  cloud :client do
    using :ec2
    settings = settings_for_node(POOL_NAME, :client)
    instances                   1..1
    is_generic_node             settings
    sends_aws_keys              settings
    is_spot_priced              settings
    user                        'ubuntu'
    user_data                   settings[:attributes].to_json
  end
end
