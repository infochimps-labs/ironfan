name        'ec2_instance_store'
description 'RAID the ephemeral instance store drives'

run_list *%w[
  ec2::raid_ephemeral
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
                   })

