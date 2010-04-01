name        'ebs_volumes_mount'
description "Mounts ebs volumes once they're attached"

run_list *%w[
  aws
  ebs::wait_for_attachment
  ebs::mount_volumes_from_cluster_role_index
]
