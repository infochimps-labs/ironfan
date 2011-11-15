maintainer       "Chris Howe - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures ganglia"

depends          "java"
depends          "provides_service"

recipe           "ganglia::client",                    "Client"
recipe           "ganglia::default",                   "Default"
recipe           "ganglia::gmetad",                    "Gmetad"
recipe           "ganglia::server",                    "Server"

%w[ debian ubuntu ].each do |os|
  supports os
end
