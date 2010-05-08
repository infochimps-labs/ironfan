POOL_NAME     = 'zaius'
require File.dirname(__FILE__)+'/cloud_aspects'

#
# EBS-backed hadoop cluster in the cloud.
# See the ../README.textile file for usage, etc
# If you use the west coast availability zone, to avoid 'ami not found' errors, first run
#   export EC2_URL=https://us-west-1.ec2.amazonaws.com

pool POOL_NAME do
  cloud :master do
    using :ec2
    settings = settings_for_node(POOL_NAME, :master)
    instances                   1..1
    is_generic_node             settings
    sends_aws_keys              settings
    is_chef_client              settings
    #
    is_hadoop_node              settings
    is_hadoop_master            settings
    is_hadoop_worker            settings
    #
    has_big_package             settings
    user_data                   settings[:attributes].to_json
    is_spot_priced              settings
    user                        'ubuntu'
  end

  cloud :slave do
    using :ec2
    settings = settings_for_node(POOL_NAME, :slave)
    instances                   1..1
    is_generic_node             settings
    sends_aws_keys              settings
    is_chef_client              settings
    #
    is_hadoop_node              settings
    is_hadoop_worker            settings
    #
    has_big_package             settings
    is_spot_priced              settings
    user_data                   settings[:attributes].to_json
    user                        'ubuntu'
  end
end
