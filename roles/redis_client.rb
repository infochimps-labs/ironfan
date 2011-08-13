name        "redis_client"
description "A redis database client"

# List of recipes and roles to apply
run_list(*%w[
  redis
  redis::install_from_release
])
