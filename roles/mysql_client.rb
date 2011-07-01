name        "mysql_client"
description "A mysql database client"

# List of recipes and roles to apply
run_list(*%w[
  mysql
  mysql::client
])
