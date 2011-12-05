name        'ebs_volumes_attach'
description "Attaches ebs volumes"

run_list *%w[
  aws
  xfs
  volumes::attach
]
