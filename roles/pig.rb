name 'pig'
description 'Installs pig with piggybank and extra jars.'

run_list %w[
  pig
  pig::install_from_release
  pig::piggybank
  pig::integration
]
