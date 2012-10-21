name        'systemwide'
description 'top level attributes, applies to all nodes'

run_list *%w[
  build-essential
  motd
  zsh
  emacs
  ntp
]
