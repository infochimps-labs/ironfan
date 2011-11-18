name        "elasticsearch_http_esnode"
description "[Infochimps internal] HTTP esnode for elasticsearch cluster."

# List of recipes and roles to apply
run_list(*%w[

  elasticsearch::autoconf
  elasticsearch::default
  elasticsearch::install_from_release
  elasticsearch::install_plugins

  nginx
  elasticsearch::http
])
