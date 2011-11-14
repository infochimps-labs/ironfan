maintainer       "37signals"
maintainer_email "sysadmins@37signals.com"
license          ""
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Configures NFS"

depends          "cluster_service_discovery"


%w[ debian ubuntu ].each do |os|
  supports os
end
