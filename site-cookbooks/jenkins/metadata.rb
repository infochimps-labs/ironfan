maintainer       "Fletcher Nichol"
maintainer_email "fnichol@nichol.ca"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.5"

description      "Installs and configures Jenkins CI server & slaves"

depends          "runit"
depends          "java"
depends          "iptables"
depends          "cluster_service_discovery"


%w[ debian ubuntu ].each do |os|
  supports os
end
