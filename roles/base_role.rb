name        'base_role'
description 'top level attributes, applies to all nodes'

run_list *%w[
  base
  aws
  java
  cluster_service_discovery
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
  })
