name        'azkaban'
description 'Runs azkaban'

run_list *%w[
  java
  runit
  azkaban
  ]
