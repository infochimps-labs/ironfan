POOL_NAME     = 'clyde'
POOL_SETTINGS = Settings[:pools][POOL_NAME.to_sym]
require File.dirname(__FILE__)+'/../settings'
require File.dirname(__FILE__)+'/cloud_aspects'

#
# EBS-backed hadoop cluster in the cloud.
# See the ../README.textile file for usage, etc
# If you're on the west coast, to avoid 'ami not found' errors, first run
#   export EC2_URL=https://us-west-1.ec2.amazonaws.com

pool POOL_NAME do
  cloud :master do
    instances        1..1
    image_id         AMIS[:canonical_ubuntu_910][:x32_uswest1_ebs]
    chef_hash      = POOL_SETTINGS[:common][:user_data]
    chef_hash.merge!(POOL_SETTINGS[:master][:user_data])
    elastic_ip       POOL_SETTINGS[:master][:elastic_ip]
    chef_hash.merge!({:node_name => POOL_NAME+'-master'})
    is_generic_node
    is_hadoop_node
    is_chef_client
    is_nfs_client(chef_hash[:attributes])
    disable_api_termination false
    user_data  chef_hash.to_json
  end

  cloud :slave do
    instances        1..1
    image_id         AMIS[:canonical_ubuntu_910][:x32_uswest1_ebs]
    chef_hash      = POOL_SETTINGS[:common][:user_data]
    chef_hash.merge!(POOL_SETTINGS[:slave][:user_data])
    elastic_ip       POOL_SETTINGS[:slave][:elastic_ip]
    chef_hash.merge!({:node_name => POOL_NAME+'-worker'})
    is_generic_node
    is_hadoop_node
    is_chef_client
    is_nfs_client(   chef_hash[:attributes])
    is_hadoop_worker(chef_hash[:attributes])
    disable_api_termination false
    user_data  chef_hash.to_json
  end
end
