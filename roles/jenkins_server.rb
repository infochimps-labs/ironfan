name        'jenkins_server'
description 'installs the jenkins server'

run_list *%w[
  jenkins
  jenkins::user_key
  jenkins::server
  ]
