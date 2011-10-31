#
# Cookbook Name:: hadoop_cluster
# Recipe::        ec2_conf
#

Chef::Log.info(hadoop_config_hash.inspect)


#
# Mounting things is now done in mountable_volumes::mount
#

# FIXME: move the EC2-specific stuff out of attributes/hadoop_cluster into here
