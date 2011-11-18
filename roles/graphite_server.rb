name        'graphite_server'
description 'installs graphite and launches its web services'

run_list *%w[
  graphite
  graphite::carbon
  graphite::web
  graphite::whisper
  ]
  # graphite::ganglia
