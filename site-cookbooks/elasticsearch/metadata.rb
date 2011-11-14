maintainer       "GoTime, modifications by Infochimps"
maintainer_email "ops@gotime.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures elasticsearch"

depends          "java"
depends          "runit"
depends          "aws"
depends          "cluster_service_discovery"


%w[ debian ubuntu ].each do |os|
  supports os
end
