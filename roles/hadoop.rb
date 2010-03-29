require File.dirname(__FILE__)+'/../settings'

# Install with
#   knife role from file roles/base_role.rb

name 'hadoop'
description 'applies to all nodes in the hadoop cluster'

run_list *%w[
  cdh
  cdh::pig
  cdh::ec2_conf
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
    :hadoop => {
      :hadoop_handle => 'hadoop-0.20',
      :cdh_version   => 'cdh3',
    }
  })
