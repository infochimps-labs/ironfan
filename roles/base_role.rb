name        'base_role'
description 'top level attributes, applies to all nodes'

run_list *%w[
  cluster_chef::node_name

  build-essential
  ubuntu
  motd

  ]
