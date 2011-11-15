maintainer       "Heavy Water Software Inc."
maintainer_email "darrin@heavywater.ca"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.5"

description      "Installs/Configures graphite"

depends          "python"
depends          "apache2"
depends          "ganglia"

recipe           "graphite::carbon",                   "Carbon"
recipe           "graphite::default",                  "Base configuration for graphite"
recipe           "graphite::ganglia",                  "Ganglia"
recipe           "graphite::web",                      "Web"
recipe           "graphite::whisper",                  "Whisper"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "graphite/carbon/line_receiver_interface",
  :display_name          => "",
  :description           => "",
  :default               => "127.0.0.1"

attribute "graphite/carbon/pickle_receiver_interface",
  :display_name          => "",
  :description           => "",
  :default               => "127.0.0.1"

attribute "graphite/carbon/cache_query_interface",
  :display_name          => "",
  :description           => "",
  :default               => "127.0.0.1"

attribute "graphite/carbon/version",
  :display_name          => "",
  :description           => "",
  :default               => "0.9.7"

attribute "graphite/carbon/uri",
  :display_name          => "",
  :description           => "",
  :default               => "http://launchpadlibrarian.net/61904798/carbon-0.9.7.tar.gz"

attribute "graphite/carbon/checksum",
  :display_name          => "",
  :description           => "",
  :default               => "ba698aca"

attribute "graphite/whisper/version",
  :display_name          => "",
  :description           => "",
  :default               => "0.9.7"

attribute "graphite/whisper/uri",
  :display_name          => "",
  :description           => "",
  :default               => "http://launchpadlibrarian.net/61904764/whisper-0.9.7.tar.gz"

attribute "graphite/whisper/checksum",
  :display_name          => "",
  :description           => "",
  :default               => "c6272ad6"

attribute "graphite/graphite_web/version",
  :display_name          => "",
  :description           => "",
  :default               => "0.9.7c"

attribute "graphite/graphite_web/uri",
  :display_name          => "",
  :description           => "",
  :default               => "http://launchpadlibrarian.net/62379635/graphite-web-0.9.7c.tar.gz"

attribute "graphite/graphite_web/checksum",
  :display_name          => "",
  :description           => "",
  :default               => "a3e16265"
