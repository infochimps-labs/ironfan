# Install with `knife role from file roles/hadoop.rb`
name        'hadoop'
description 'applies to all nodes in the hadoop cluster'
require File.dirname(__FILE__)+'/../settings'

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
    },
    # Needed if you want to access S3 files via s3n:// and s3:// urls
    :aws => {
      :aws_access_key        => Settings[:access_key],
      :aws_secret_access_key => Settings[:secret_access_key],
      :aws_region            => Settings[:aws_region],
      :availability_zone     => Settings[:availability_zones].first,
    },
  })
