maintainer       "Mike Heffner"
maintainer_email "mike@librato.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "Installs/Configures firewall"

depends          "iptables"

recipe           "firewall::default",                  "Base configuration for firewall"
recipe           "firewall::port_scan",                "Port Scan"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "firewall/port_scan",
  :display_name          => "",
  :description           => "The recipe 'firewall::port_scan' will search for all properties named 'node[:firewall][:port_scan_*]'. This will create a rule that allows only ':max_conns' connections with a window period of ':window' seconds. For example, the settings above state that a maximum of 20 connections  can be made to the ssh port (22) within a period of 5 seconds. If any more than that are made within 5 seconds, the source will automatically be dropped.",
  :default               => "{ :window => 5, :max_conns => 20, :port => 22 }"
