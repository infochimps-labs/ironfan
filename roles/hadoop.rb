require File.join(File.dirname(__FILE__), '/../clouds/cloud_aspects')
# Install with `knife role from file roles/hadoop.rb`
name        'hadoop'
description 'applies to all nodes in the hadoop cluster'
require 'configliere'
Settings.read File.join(ENV['HOME'],'.chef','cluster_chef.yaml'); Settings.resolve!

run_list *%w[
  hadoop_cluster
  hadoop_cluster::cluster_conf
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
    # Needed if you want to access S3 files via s3n:// and s3:// urls
    :aws => {
      :aws_access_key        => Settings[:access_key],
      :aws_secret_access_key => Settings[:secret_access_key],
      :aws_region            => Settings[:aws_region],
      :availability_zone     => Settings[:availability_zones].first,
    },
  })
