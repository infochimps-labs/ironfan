# http://wiki.opscode.com/display/chef/Metadata
maintainer        "Infochimps.com"
maintainer_email  "help@infochimps.com"
license           "Apache 2.0"
description       "Installs hadoop and sets up a high-performance cluster. Inspired by Tom White / Cloudera's hadoop-ec2 command line utilities"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.10.0"

depends           "java"
depends           "mountable_volumes"
depends           "aws"
depends           "ubuntu"
depends           "cluster_service_discovery"

%w{ debian ubuntu }.each do |os|
  supports os
end
