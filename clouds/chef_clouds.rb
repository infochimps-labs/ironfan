POOL_NAME     = 'westchef'
require File.dirname(__FILE__)+'/cloud_aspects'

# Example usage (starts the chef server, then logs in to it)
#   cloud-start -n server -c cloud/chef_clouds.rb
#   cloud-ssh   -n server -c cloud/chef_clouds.rb
# If you're on the west coast, to avoid 'ami not found' errors, first run
#   export EC2_URL=https://us-west-1.ec2.amazonaws.com

pool POOL_NAME do
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
    user_data                   bootstrap_chef_script(:server, settings)
  end

  cloud :bootstrap_client do
    using :ec2
    settings = settings_for_node(POOL_NAME, :client)
    instances                   1..1
    is_nfs_client               settings
    is_generic_node             settings
    sends_aws_keys              settings
    is_chef_client              settings
    is_spot_priced              settings
    user                        'ubuntu'
    user_data                   bootstrap_chef_script(:client, settings)
    $stderr.puts settings[:attributes].to_json
  end

  cloud :client do
    using :ec2
    settings = settings_for_node(POOL_NAME, :client)
    instances                   1..1
    is_nfs_client               settings
    is_generic_node             settings
    sends_aws_keys              settings
    is_chef_client              settings
    is_spot_priced              settings
    user                        'ubuntu'
    user_data                   settings[:attributes].to_json
    $stderr.puts settings[:attributes].to_json
  end
end
