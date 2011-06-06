name        'base_role'
description 'top level attributes, applies to all nodes'

run_list *%w[
  ubuntu
  motd
  ]
