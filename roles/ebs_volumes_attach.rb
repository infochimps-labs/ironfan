name        'attaches_ebs_volumes'
description "Attaches ebs volumes"

run_list *%w[
  aws
  xfs
  ebs::attach_volumes_from_cluster_role_index
]
