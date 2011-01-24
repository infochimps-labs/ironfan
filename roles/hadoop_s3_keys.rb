name        'hadoop_s3_keys'
description 'applies to all nodes in the hadoop cluster'

# Attributes applied if the node doesn't have it set already.
default_attributes({
    # Needed if you want to access S3 files via s3n:// and s3:// urls
    :aws => {
      :aws_access_key        => Chef::Config.knife[:aws_access_key_id],
      :aws_access_key_id     => Chef::Config.knife[:aws_access_key_id],
      :aws_secret_access_key => Chef::Config.knife[:aws_secret_access_key],
    },
  })
