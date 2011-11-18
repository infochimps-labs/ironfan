maintainer       "Nathaniel Eliot - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures statsd"

depends          "runit"
depends          "nodejs"
depends          "graphite"

recipe           "statsd::default",                    "Base configuration for statsd"
recipe           "statsd::server",                     "Server"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "statsd/cluster_name",
  :display_name          => "",
  :description           => "",
  :default               => "cluster_name"

attribute "statsd/git_repo",
  :display_name          => "",
  :description           => "",
  :default               => "https://github.com/etsy/statsd.git"

attribute "statsd/install_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/src/statsd"

attribute "statsd/port",
  :display_name          => "",
  :description           => "",
  :default               => "8125"

attribute "statsd/flush_interval",
  :display_name          => "",
  :description           => "",
  :default               => "10000"

attribute "statsd/graphite/port",
  :display_name          => "",
  :description           => "",
  :default               => "2003"

attribute "statsd/graphite/addr",
  :display_name          => "",
  :description           => "",
  :default               => "localhost"

attribute "groups/statsd/gid",
  :display_name          => "",
  :description           => "",
  :default               => "310"
