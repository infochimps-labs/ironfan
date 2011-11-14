maintainer       "Nathaniel Eliot - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures statsd"

depends          "runit"
depends          "nodejs"
depends          "graphite"


%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "statsd/cluster_name",
  :default               => "cluster_name",
  :display_name          => "",
  :description           => ""

attribute "statsd/git_uri",
  :default               => "https://github.com/etsy/statsd.git",
  :display_name          => "",
  :description           => ""

attribute "statsd/src_path",
  :default               => "/usr/src/statsd",
  :display_name          => "",
  :description           => ""

attribute "statsd/port",
  :default               => "8125",
  :display_name          => "",
  :description           => ""

attribute "statsd/flushInterval",
  :default               => "10000",
  :display_name          => "",
  :description           => ""

attribute "statsd/graphite/port",
  :default               => "2003",
  :display_name          => "",
  :description           => ""

attribute "statsd/graphite/host",
  :default               => "localhost",
  :display_name          => "",
  :description           => ""
