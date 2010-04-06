name        'base_role'
description 'top level attributes, applies to all nodes'

run_list *%w[
  base
  java
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
  })
