name        'benchmarkable'
description 'Installs simple benchmark tools to know which machines are intrinsically awesome or sucky'

run_list *%w[
  benchmarkable::bonnie
  benchmarkable::hardinfo
  ]
