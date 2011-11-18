name        'statsd_server'
description 'installs and launches statsd'

run_list *%w[
  statsd
  statsd::server
  ]
