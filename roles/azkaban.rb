name        'azkaban'
description 'Runs azkaban'

# FIXME what are these?
run_list *%w[
  java
  runit
  azkaban
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
  })
