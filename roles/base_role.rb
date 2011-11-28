name        'base_role'
description 'top level attributes, applies to all nodes'

run_list *%w[
  apt
  build-essential
  ubuntu
  motd

  java
  zsh
  ntp

  xml
  zlib
  ]
