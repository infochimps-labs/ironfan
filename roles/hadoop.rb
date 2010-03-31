require File.dirname(__FILE__)+'/../settings'

# Install with
#   knife role from file roles/base_role.rb

name 'hadoop'
description 'applies to all nodes in the hadoop cluster'

run_list *%w[
  hadoop_cluster
  hadoop_cluster::pig
  hadoop_cluster::ec2_conf
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
    # :ebs_volumes => [
    #   '/ebs1' => { :type => 'xfs', :device => '/dev/sdj' }
    #   '/ebs2' => { :type => 'xfs', :device => '/dev/sdk' }
    # ],
    :hadoop => {
      :hadoop_handle => 'hadoop-0.20',
      :cdh_version   => 'cdh3',
    }
  })
