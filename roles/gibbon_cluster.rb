name        'gibbon_cluster'
description 'Holds cluster-specific overrides and recipes for the gibbon_cluster'

run_list *%w[
  ]

# Force these attributes overriding all else
override_attributes({
    :cluster_size => 33,
  })

# Attributes applied if the node doesn't have it set already.
default_attributes({
  })
