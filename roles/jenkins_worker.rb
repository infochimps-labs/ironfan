name        'jenkins_worker'
description 'installs the jenkins worker using jnlp'

run_list *%w[
  jenkins
  jenkins::node_ssh
  jenkins::build_from_github
  jenkins::build_ruby_rspec
  ]
