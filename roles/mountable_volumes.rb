name        'volumes'
description 'mounts attached volumes as described by node attributes'

run_list(*[
    'xfs',
    'volumes::mount',
  ])
