name        'gibbon_cluster'
description 'Holds cluster-specific overrides and recipes for the gibbon_cluster'

# Force these attributes overriding all else
override_attributes({
    :cluster_size => 33,
  })
