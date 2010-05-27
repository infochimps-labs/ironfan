name        'azkaban'
description 'Runs azkaban'

# FIXME what are these?
run_list *%w[
  java
  runit
  azkaban::install_from_release
  azkaban::default
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
  })
