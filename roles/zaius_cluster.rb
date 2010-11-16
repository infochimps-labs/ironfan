name        'zaius_cluster'
description 'Holds cluster-specific overrides and recipes for the zaius_cluster'

# Force these attributes overriding all else
override_attributes({
    :cluster_size => 4,
  })
