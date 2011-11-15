maintainer       "Mike Heffner"
maintainer_email "mike@librato.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures firewall"

depends          "iptables"

recipe           "firewall::default",                  "Base configuration for firewall"
recipe           "firewall::port_scan",                "Port Scan"

%w[ debian ubuntu ].each do |os|
  supports os
end
