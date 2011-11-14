maintainer       "Mike Heffner"
maintainer_email "mike@librato.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures ec2-specific capabilites"



%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "ec2/raid_level",
  :default               => "0",
  :display_name          => "",
  :description           => ""

attribute "ec2/raid_read_ahead",
  :default               => "65536",
  :display_name          => "",
  :description           => ""

attribute "ec2/raid_mount",
  :default               => "/raid0",
  :display_name          => "",
  :description           => ""
