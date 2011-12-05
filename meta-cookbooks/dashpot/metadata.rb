maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.2"

description      "Creates and serves a lightweight pluggable dashboard for a machine"

depends          "runit"
depends          "provides_service"

recipe           "dashpot",       "Lightweight dashboard for this machine: index of services and their dashboard snippets"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "cluster_chef/conf_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/etc/cluster_chef"

attribute "cluster_chef/log_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/var/log/cluster_chef"

attribute "cluster_chef/home_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/etc/cluster_chef"

attribute "cluster_chef/user",
  :display_name          => "",
  :description           => "",
  :default               => "root"

attribute "cluster_chef/thttpd/port",
  :display_name          => "",
  :description           => "",
  :default               => "6789"

attribute "cluster_chef/dashboard/run_state",
  :display_name          => "",
  :description           => "",
  :default               => "start"
