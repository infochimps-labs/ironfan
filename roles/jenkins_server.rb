name        'jenkins_server'
description 'installs the jenkins server'

run_list *%w[
  jenkins
  jenkins::user_key
  jenkins::server
  jenkins::build_from_github
  jenkins::build_ruby_rspec
  ]
