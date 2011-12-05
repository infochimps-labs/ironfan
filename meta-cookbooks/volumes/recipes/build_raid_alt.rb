#
# Cookbook Name::       ec2
# Description::         Build a RAID volume out of the ephemeral drives
# Recipe::              raid_ephemeral
# Author::              Mike Heffner (<mike@librato.com>)
#
# Copyright 2011, Librato, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Sets up a RAID device on the ephemeral instance store drives.
# Modeled after:
# https://github.com/riptano/CassandraClusterAMI/blob/master/.startcassandra.py
#

# Remove EC2 default /mnt from fstab
ruby_block "remove_mnt_from_fstab" do
  block do
    lines = File.readlines("/etc/fstab")
    File.open("/etc/fstab", "w") do |f|
      lines.each do |l|
        f << l unless l.include?("/mnt")
      end
    end
  end
  only_if {File.read("/etc/fstab").include?("/mnt")}
end

ruby_block "format_drives" do
  block do
    devices = %x{ls /dev/sd*}.split("\n").delete_if{|d| d=="/dev/sda1"}

    Chef::Log.info("Formatting drives #{devices.join(",")}")

    # Create one giant Linux partition per drive
    fmtcmd=",,L\n"
    devices.each do |dev|
      system("umount #{dev}")
      IO.popen("sfdisk --no-reread #{dev}", "w") do |f|
        f.puts fmtcmd
      end
    end
  end

  # XXX: fix this
  not_if {File.exist?("/dev/sdc1")}
end

package "mdadm"
package "xfsprogs"

ruby_block "create_raid" do
  block do
    # Get partitions
    parts = %x{ls /dev/sd*[0-9]}.split("\n").delete_if{|d| d=="/dev/sda1"}
    Chef::Log.info("Partitions to raid: #{parts.join(",")}")

    # Unmount
    parts.each do |part|
      system("umount #{part}")
    end

    args = ['--create /dev/md0',
            '--chunk=256',
            "--level #{node[:ec2][:raid][:level]}",
            "--raid-devices #{parts.length}"]
    r = system("mdadm #{args.join(' ')} #{parts.join(' ')}")
    raise "Failed to create raid" unless r

    # Scan
    File.open("/etc/mdadm/mdadm.conf", "a") do |f|
      f << "DEVICE #{parts.join(' ')}\n"
    end
    r = system("mdadm --examine --scan >> /etc/mdadm/mdadm.conf")
    raise "Failed to initialize raid device" unless r

    r = system("blockdev --setra #{node[:ec2][:raid][:read_ahead]} /dev/md0")
    raise "Failed to set read-ahead" unless r

    r = system("mkfs.xfs -f /dev/md0")
    raise "Failed to format raid device" unless r
  end

  not_if {File.exist?("/dev/md0")}
end

ruby_block "add_raid_device_to_fstab" do
  block do
    File.open("/etc/fstab", "a") do |f|
      fstab = ['/dev/md0', node[:ec2][:raid][:mount], 'xfs',
               'defaults,nobootwait,noatime', '0', '0']
      f << "#{fstab.join("\t")}\n"
    end
  end

  not_if {File.read("/etc/fstab").include?(node[:ec2][:raid][:mount])}
end

ruby_block "mount_raid" do
  block do
    system("mkdir -p #{node[:ec2][:raid][:mount]}")
    system("mount #{node[:ec2][:raid][:mount]}")
  end

  not_if {File.read("/proc/mounts").include?(node[:ec2][:raid][:mount])}
end
