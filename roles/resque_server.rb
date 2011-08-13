name        'resque_server'
description 'installs resque and launches its redis and web services'

run_list *%w[
  redis::base
  redis::install_from_package
  resque
  resque::server
  ]
