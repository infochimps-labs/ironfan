name        "elasticsearch_peer"
description "[Infochimps internal] Data esnode (holds and indexes data) for elasticsearch cluster."

# List of recipes and roles to apply
run_list(*%w[
  hadoop_cluster::system_internals
  elasticsearch::build_raid
  elasticsearch::default
  elasticsearch::install_from_release
  elasticsearch::install_plugins
  elasticsearch::server
  elasticsearch::http
])
