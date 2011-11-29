maintainer       "Chris Howe - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures ganglia"

depends          "java"
depends          "runit"
depends          "cluster_chef"
depends          "provides_service"

recipe           "ganglia::default",                   "Base configuration for ganglia"
recipe           "ganglia::server",                    "Ganglia server -- contact point for all ganglia_monitors"
recipe           "ganglia::monitor",                   "Ganglia monitor -- discovers and sends to its ganglia_server"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "ganglia/home_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/var/lib/ganglia"

attribute "ganglia/log_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/var/log/ganglia"

attribute "ganglia/conf_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/etc/ganglia"
