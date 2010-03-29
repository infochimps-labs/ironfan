name 'hadoop_worker'
description 'runs one of many workers in fully-distributed mode.'
run_list *%w[
  ec2::filesystems
  cdh::worker
  cdh::ec2_conf
]

default_attributes({
    :nfs_mounts => ['/home', { :owner => 'root', :device => '' }],
  })
