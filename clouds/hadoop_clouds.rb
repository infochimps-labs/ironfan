POOL_NAME     = 'clyde'
require File.dirname(__FILE__)+'/../settings'
require File.dirname(__FILE__)+'/cloud_aspects'

#
# EBS-backed hadoop cluster in the cloud.
# See the ../README.textile file for usage, etc
# If you're on the west coast, to avoid 'ami not found' errors, first run
#   export EC2_URL=https://us-west-1.ec2.amazonaws.com

pool POOL_NAME do
  cloud :master do
    using :ec2
    settings = settings_for_node(POOL_NAME, :master)
    instances           1..1
    is_nfs_client       settings
    is_generic_node     settings
    is_chef_client      settings
    is_hadoop_node      settings
    is_hadoop_master    settings
    is_hadoop_worker    settings
    image_id            AMIS[:infochimps_ubuntu_910][:x32_uswest1_ebs]
    elastic_ip          settings[:elastic_ip]
    user_data           settings.to_json
    disable_api_termination false
  end

  cloud :slave do
    using :ec2
    settings = settings_for_node(POOL_NAME, :slave)
    instances           1..1
    is_nfs_client       settings
    is_generic_node     settings
    is_chef_client      settings
    is_hadoop_node      settings
    is_hadoop_worker    settings
    image_id            AMIS[:infochimps_ubuntu_910][:x32_uswest1_ebs]
    elastic_ip          settings[:elastic_ip]
    user_data           settings.to_json
    disable_api_termination false
  end
end
