name        'graphite_server'
description 'installs graphite and launches its web services'

run_list *%w[
  graphite
  graphite::carbon
  graphite::ganglia
  graphite::web
  graphite::whisper
  ]
