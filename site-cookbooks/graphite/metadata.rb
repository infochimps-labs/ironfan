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
