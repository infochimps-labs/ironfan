maintainer       "Mike Heffner"
maintainer_email "mike@librato.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.2"

description      "Installs/Configures ec2-specific capabilites"

depends          "aws"
depends          "mountable_volumes"
depends          "cluster_chef"

recipe           "ec2::default",                       "Placeholder cookbook -- see ec2::raid_ephemeral"
recipe           "ec2::attach_ebs",                    "Attach EBS volumes as directed by node[:mountable_volumes]"
recipe           "ec2::raid_ephemeral",                "Build a RAID volume out of the ephemeral drives"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "ec2/raid/level",
  :display_name          => "Raid level to apply to the volume.",
  :description           => "Raid level to apply to the volume. See the mdadm documentation",
  :default               => "0"

attribute "ec2/raid/read_ahead",
  :display_name          => "",
  :description           => "",
  :default               => "65536"

attribute "ec2/raid/mount",
  :display_name          => "",
  :description           => "",
  :default               => "/raid0"
