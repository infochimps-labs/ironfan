name        'base_role'
description 'top level attributes, applies to all nodes'

run_list *%w[
  base
  sudo
  users
  git
  java
  emacs
  build-essential
  xml
  zlib

  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
  })
