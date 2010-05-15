name        'pig'
description 'Runs pig'

# FIXME what are these?
run_list *%w[
  java
  runit
  pig::install_from_release
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
  })
