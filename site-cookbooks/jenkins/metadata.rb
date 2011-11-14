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
  :default               => "http://pkg.jenkins-ci.org/debian",
  :display_name          => "",
  :description           => ""

attribute "jenkins/plugins_mirror",
  :default               => "http://updates.jenkins-ci.org",
  :display_name          => "",
  :description           => ""

attribute "jenkins/java_home",
  :default               => "/System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Home",
  :display_name          => "",
  :description           => ""

attribute "jenkins/iptables_allow",
  :default               => "enable",
  :display_name          => "",
  :description           => ""

attribute "jenkins/server/home",
  :default               => "/var/lib/jenkins",
  :display_name          => "",
  :description           => ""

attribute "jenkins/server/user",
  :default               => "jenkins",
  :display_name          => "",
  :description           => ""

attribute "jenkins/server/group",
  :default               => "nogroup",
  :display_name          => "",
  :description           => ""

attribute "jenkins/server/port",
  :default               => "8080",
  :display_name          => "",
  :description           => ""

attribute "jenkins/server/host",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/server/jvm_heap",
  :default               => "384",
  :display_name          => "",
  :description           => ""

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
  :default               => "ubuntu 10.4 [  ] slave on hostname",
  :display_name          => "",
  :description           => ""

attribute "jenkins/node/executors",
  :default               => "1",
  :display_name          => "",
  :description           => ""

attribute "jenkins/node/home",
  :default               => "/var/lib/jenkins-node",
  :display_name          => "",
  :description           => ""

attribute "jenkins/node/labels",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/node/mode",
  :default               => "normal",
  :display_name          => "",
  :description           => ""

attribute "jenkins/node/launcher",
  :default               => "ssh",
  :display_name          => "",
  :description           => ""

attribute "jenkins/node/availability",
  :default               => "always",
  :display_name          => "",
  :description           => ""

attribute "jenkins/node/in_demand_delay",
  :default               => "0",
  :display_name          => "",
  :description           => ""

attribute "jenkins/node/idle_delay",
  :default               => "1",
  :display_name          => "",
  :description           => ""

attribute "jenkins/node/env",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/node/user",
  :default               => "jenkins-node",
  :display_name          => "",
  :description           => ""

attribute "jenkins/node/ssh_host",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/node/ssh_port",
  :default               => "22",
  :display_name          => "",
  :description           => ""

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
  :default               => "disable",
  :display_name          => "",
  :description           => ""

attribute "jenkins/http_proxy/listen_ports",
  :type                  => "array",
  :default               => [80],
  :display_name          => "",
  :description           => ""

attribute "jenkins/http_proxy/host_name",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/http_proxy/host_aliases",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "jenkins/http_proxy/client_max_body_size",
  :default               => "1024m",
  :display_name          => "",
  :description           => ""
