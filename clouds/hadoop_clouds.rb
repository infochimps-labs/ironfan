POOL_NAME     = 'gibbon'
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
    instances            1..1
    attaches_ebs_volumes        settings
    is_nfs_client               settings
    is_generic_node             settings
    sends_aws_keys              settings
    is_chef_client              settings
    #
    is_hadoop_node              settings
    mounts_ebs_volumes          settings
    has_role   settings, "hadoop_master"
    has_role   settings, "hadoop_worker"
    has_recipe settings, "pig::install_from_release"
    has_big_package             settings
    is_cassandra_node           settings
    #
    user_data                   settings[:user_data].to_json
    is_spot_priced              settings
    user                        'ubuntu'
  end

  cloud :slave do
    using :ec2
    settings = settings_for_node(POOL_NAME, :slave)
    instances                   30..30
    attaches_ebs_volumes        settings
    is_nfs_client               settings
    is_generic_node             settings
    sends_aws_keys              settings
    is_chef_client              settings
    #
    is_hadoop_node              settings
    mounts_ebs_volumes          settings
    has_role   settings, "hadoop_worker"
    has_recipe settings, "pig::install_from_release"
    has_big_package             settings
    is_cassandra_node           settings
    #
    is_spot_priced              settings
    user                        'ubuntu'
    user_data                   (settings[:user_data].merge(settings[:user_data][:attributes])).to_json
  end
end
