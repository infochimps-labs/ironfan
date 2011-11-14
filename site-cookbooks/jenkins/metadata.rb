maintainer       "Fletcher Nichol"
maintainer_email "fnichol@nichol.ca"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.5"

description      "Installs and configures Jenkins CI server & slaves"

depends          "runit"
depends          "java"
depends          "iptables"
depends          "provides_service"


%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "jenkins/apt_mirror",
  :display_name          => "",
  :description           => "",
  :default               => "http://pkg.jenkins-ci.org/debian"

attribute "jenkins/plugins_mirror",
  :display_name          => "",
  :description           => "",
  :default               => "http://updates.jenkins-ci.org"

attribute "jenkins/java_home",
  :display_name          => "",
  :description           => "",
  :default               => "/System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Home"

attribute "jenkins/iptables_allow",
  :display_name          => "",
  :description           => "",
  :default               => "enable"

attribute "jenkins/server/home",
  :display_name          => "",
  :description           => "",
  :default               => "/var/lib/jenkins"

attribute "jenkins/server/user",
  :display_name          => "",
  :description           => "",
  :default               => "jenkins"

attribute "jenkins/server/group",
  :display_name          => "",
  :description           => "",
  :default               => "nogroup"

attribute "jenkins/server/port",
  :display_name          => "",
  :description           => "",
  :default               => "8080"

attribute "jenkins/server/host",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/server/jvm_heap",
  :display_name          => "",
  :description           => "",
  :default               => "384"

attribute "jenkins/server/plugins",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/server/use_head",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/node/name",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/node/description",
  :display_name          => "",
  :description           => "",
  :default               => "ubuntu 10.4 [  ] slave on hostname"

attribute "jenkins/node/executors",
  :display_name          => "",
  :description           => "",
  :default               => "1"

attribute "jenkins/node/home",
  :display_name          => "",
  :description           => "",
  :default               => "/var/lib/jenkins-node"

attribute "jenkins/node/labels",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/node/mode",
  :display_name          => "",
  :description           => "",
  :default               => "normal"

attribute "jenkins/node/launcher",
  :display_name          => "",
  :description           => "",
  :default               => "ssh"

attribute "jenkins/node/availability",
  :display_name          => "",
  :description           => "",
  :default               => "always"

attribute "jenkins/node/in_demand_delay",
  :display_name          => "",
  :description           => "",
  :default               => "0"

attribute "jenkins/node/idle_delay",
  :display_name          => "",
  :description           => "",
  :default               => "1"

attribute "jenkins/node/env",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/node/user",
  :display_name          => "",
  :description           => "",
  :default               => "jenkins-node"

attribute "jenkins/node/ssh_host",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/node/ssh_port",
  :display_name          => "",
  :description           => "",
  :default               => "22"

attribute "jenkins/node/ssh_pass",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/node/jvm_options",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/node/ssh_private_key",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/http_proxy/variant",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/http_proxy/www_redirect",
  :display_name          => "",
  :description           => "",
  :default               => "disable"

attribute "jenkins/http_proxy/listen_ports",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => [80]

attribute "jenkins/http_proxy/host_name",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/http_proxy/host_aliases",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/http_proxy/client_max_body_size",
  :display_name          => "",
  :description           => "",
  :default               => "1024m"
