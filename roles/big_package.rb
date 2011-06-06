name        'big_package'
description "A bunch of useful packages to include."

# Recipes to run
run_list *%w[
  big_package
  big_package::ruby
 ]
