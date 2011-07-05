name        'big_package'
description 'Many convenience packages in one big blump'

run_list *%w[
  big_package
  big_package::python
  big_package::ruby
  big_package::emacs
  big_package::other
]
