name        'jenkins_worker'
description 'installs the jenkins worker using jnlp'

run_list *%w[
  jenkins
  jenkins::node_jnlp
  ]
