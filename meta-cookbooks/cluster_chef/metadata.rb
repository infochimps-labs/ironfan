maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures cluster_chef"

depends          "runit"
depends          "provides_service"

recipe           "cluster_chef::burn_ami_prep",        "Burn Ami Prep"
recipe           "cluster_chef::dashboard",            "Lightweight dashboard for this machine: index of services and their dashboard snippets"
recipe           "cluster_chef::dedicated_server_tuning", "Dedicated Server Tuning"
recipe           "cluster_chef::default",              "Base configuration for cluster_chef"
recipe           "cluster_chef::virtualbox_metadata",  "Virtualbox Metadata"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "server_tuning/ulimit",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "server_tuning/overcommit_memory",
  :display_name          => "",
  :description           => "",
  :default               => "1"

attribute "server_tuning/overcommit_ratio",
  :display_name          => "",
  :description           => "",
  :default               => "100"

attribute "server_tuning/swappiness",
  :display_name          => "",
  :description           => "",
  :default               => "5"

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

attribute "users/root/primary_group",
  :display_name          => "",
  :description           => "",
  :default               => "root"
