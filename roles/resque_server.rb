name        'resque_server'
description 'installs resque and launches its redis and web services'

run_list *%w[
  redis::install_from_release
  redis::server
  resque
  resque::server
  ]
