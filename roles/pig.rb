name 'pig'
description 'Installs pig with piggybank and extra jars.'

default_attributes({
    :java => { :install_flavor => 'sun' }
  })

run_list %w[
  pig
  pig::install_from_release
  pig::piggybank
  pig::integration
]
