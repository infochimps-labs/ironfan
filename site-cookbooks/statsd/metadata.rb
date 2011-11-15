maintainer       "Nathaniel Eliot - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures statsd"

depends          "runit"
depends          "nodejs"
depends          "graphite"

recipe           "statsd::default",                    "Default"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "statsd/cluster_name",
  :display_name          => "",
  :description           => "",
  :default               => "cluster_name"

attribute "statsd/git_uri",
  :display_name          => "",
  :description           => "",
  :default               => "https://github.com/etsy/statsd.git"

attribute "statsd/src_path",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/src/statsd"

attribute "statsd/port",
  :display_name          => "",
  :description           => "",
  :default               => "8125"

attribute "statsd/flushInterval",
  :display_name          => "",
  :description           => "",
  :default               => "10000"

attribute "statsd/graphite/port",
  :display_name          => "",
  :description           => "",
  :default               => "2003"

attribute "statsd/graphite/host",
  :display_name          => "",
  :description           => "",
  :default               => "localhost"
