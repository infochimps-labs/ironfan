maintainer       "GoTime, modifications by Infochimps"
maintainer_email "ops@gotime.com"
license          "Apache 2.0"
description      "Installs/Configures elasticsearch"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.2"

depends "java"
depends "runit"
depends "aws"
depends "cluster_service_discovery"
