name 'hadoop_master'
description 'runs a namenode, secondarynamenode, jobtracker and webfront in fully-distributed mode. There should be exactly one of these per cluster.'

run_list %w[
  ec2::filesystems
  cdh::namenode
  cdh::jobtracker
  cdh::hadoop_webfront
  cdh::ec2_conf
]

default_attributes({
    :nfs => { :exports => {
        '/home' => { :nfs_options => '*.internal(rw,no_root_squash,no_subtree_check)' },
      } },
  })
