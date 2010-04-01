name        'ebs_volumes_attach'
description "Attaches ebs volumes"

run_list *%w[
  aws
  ebs::attach_volumes_from_cluster_role_index
]

# default_attributes({
#     :ebs_volumes => {
#       :ebs1 => { :volume_id => 'vol-6e0d6e06', :device => '/dev/sdj', :mount_point => '/ebs1', :owner => 'root', :type => 'ext3'},
#     }
#   })
