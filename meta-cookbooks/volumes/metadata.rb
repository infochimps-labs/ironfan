maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "Mounts volumes as directed by node metadata. Can attach external cloud drives, such as ebs volumes."

depends          "metachef"

recipe           "volumes::default",         "Placeholder -- see other recipes in ec2 cookbook"
recipe           "volumes::mount",           "Mount the volumes listed in node[:volumes]"
recipe           "volumes::build_raid",      "Build a raid array of volumes as directed by node[:volumes]"
recipe           "volumes::build_raid_alt",  "Build a RAID volume out of the ephemeral drives"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "volumes/volumes",
  :display_name          => "Logical description of volumes on this machine",
  :description           => "This hash maps an arbitrary name for a volume to its device path, mount point, filesystem type, and so forth.\n\nvolumes understands the same arguments at the `mount` resource (nb. the prefix on `options`, `dump` and `pass`):\n\n* mount_point    (required to mount drive) The directory/path where the device should be mounted, eg '/data/redis'\n* device         (required to mount drive) The special block device or remote node, a label or an uuid to mount, eg '/dev/sdb'. See note below about Xen device name translation.\n* device_type    The type of the device specified -- :device, :label :uuid (default: `:device`)\n* fstype         The filesystem type (`xfs`, `ext3`, etc). If you omit the fstype, volumes will try to guess it from the device.\n* mount_options  Array or string containing mount options (default: `\"defaults\"`)\n* mount_dump     For entry in fstab file: dump frequency in days (default: `0`)\n* mount_pass     For entry in fstab file: Pass number for fsck (default: `2`)\n\n\nvolumes offers special helpers if you supply these additional attributes:\n\n* :scratch       if true, included in `scratch_volumes` (default: `nil`)\n* :persistent    if true, included in `persistent_volumes` (default: `nil`)\n* :attachable    used by the `ec2::attach_volumes` cookbook.\n\nHere is an example, typical of an amazon m1.large machine:\n\n  node[:volumes] = { :volumes => {\n      :scratch1 => { :device => \"/dev/sdb\",  :mount_point => \"/mnt\", :scratch => true, },\n      :scratch2 => { :device => \"/dev/sdc\",  :mount_point => \"/mnt2\", :scratch => true, },\n      :hdfs1    => { :device => \"/dev/sdj\",  :mount_point => \"/data/hdfs1\", :persistent => true, :attachable => :ebs },\n      :hdfs2    => { :device => \"/dev/sdk\",  :mount_point => \"/data/hdfs2\", :persistent => true, :attachable => :ebs },\n    }\n  }\n\nIt describes two scratch drives (fast local storage, but wiped when the machine is torn down) and two persistent drives (network-attached virtual storage, permanently available).\n\nNote: On Xen virtualization systems (eg EC2), the volumes are *renamed* from /dev/sdj to /dev/xvdj -- but the amazon API requires you refer to it as /dev/sdj.\n\nIf the `node[:virtualization][:system]` is 'xen' **and** there are no /dev/sdXX devices at all **and** there are /dev/xvdXX devices present, volumes will internally convert any device point of the form `/dev/sdXX` to `/dev/xvdXX`. If the example above is a Xen box, the values for :device will instead be `\"/dev/xvdb\"`, `\"/dev/xvdc\"`, `\"/dev/xvdj\"` and `\"/dev/xvdk\"`.\n",
  :default               => "{}"

attribute "volumes/aws_credential_source",
  :display_name          => "",
  :description           => "",
  :default               => "data_bag"

attribute "volumes/aws_credential_handle",
  :display_name          => "",
  :description           => "",
  :default               => "main"
