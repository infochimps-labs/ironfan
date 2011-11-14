maintainer       "Heavy Water Software Inc."
maintainer_email "darrin@heavywater.ca"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.5"

description      "Installs/Configures graphite"

depends          "python"
depends          "apache2"
depends          "ganglia"


%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "graphite/carbon/line_receiver_interface",
  :default               => "127.0.0.1",
  :display_name          => "",
  :description           => ""

attribute "graphite/carbon/pickle_receiver_interface",
  :default               => "127.0.0.1",
  :display_name          => "",
  :description           => ""

attribute "graphite/carbon/cache_query_interface",
  :default               => "127.0.0.1",
  :display_name          => "",
  :description           => ""

attribute "graphite/carbon/version",
  :default               => "0.9.7",
  :display_name          => "",
  :description           => ""

attribute "graphite/carbon/uri",
  :default               => "http://launchpadlibrarian.net/61904798/carbon-0.9.7.tar.gz",
  :display_name          => "",
  :description           => ""

attribute "graphite/carbon/checksum",
  :default               => "ba698aca",
  :display_name          => "",
  :description           => ""

attribute "graphite/whisper/version",
  :default               => "0.9.7",
  :display_name          => "",
  :description           => ""

attribute "graphite/whisper/uri",
  :default               => "http://launchpadlibrarian.net/61904764/whisper-0.9.7.tar.gz",
  :display_name          => "",
  :description           => ""

attribute "graphite/whisper/checksum",
  :default               => "c6272ad6",
  :display_name          => "",
  :description           => ""

attribute "graphite/graphite_web/version",
  :default               => "0.9.7c",
  :display_name          => "",
  :description           => ""

attribute "graphite/graphite_web/uri",
  :default               => "http://launchpadlibrarian.net/62379635/graphite-web-0.9.7c.tar.gz",
  :display_name          => "",
  :description           => ""

attribute "graphite/graphite_web/checksum",
  :default               => "a3e16265",
  :display_name          => "",
  :description           => ""
