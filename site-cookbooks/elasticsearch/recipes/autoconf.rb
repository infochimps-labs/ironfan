#
# Cookbook Name::       elasticsearch
# Description::         Autoconf
# Recipe::              autoconf
# Author::              GoTime, modifications by Infochimps
#
# Copyright 2010, GoTime
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
# ensure ephemeral drives are mounted
#
if node[:ec2] && node[:elasticsearch][:local_disks].nil? 
  node[:elasticsearch][:local_disks] = []
  [ [ '/mnt',  'block_device_mapping_ephemeral0'],
    [ '/mnt2', 'block_device_mapping_ephemeral1'],
    [ '/mnt3', 'block_device_mapping_ephemeral2'],
    [ '/mnt4', 'block_device_mapping_ephemeral3'],
  ].each do |mount_point, ephemeral|
    dev_str = node[:ec2][ephemeral] or next
    # sometimes ohai leaves the /dev/ off.
    dev_str = '/dev/'+dev_str unless dev_str =~ %r{^/dev/}
    # sometimes an ephemeral drive is reported that doesn't exist.
    next unless File.exists?(dev_str)
    # OK adopt the drive
    node[:elasticsearch][:local_disks] << [mount_point, dev_str]

    directory mount_point do
      owner     'root'
      group     'root'
      mode      '0755'
      action    :create
    end

    dev_fstype = fstype_from_file_magic(dev_str)
    mount mount_point do
      only_if{ dev_str && dev_fstype }
      only_if{ File.exists?(dev_str) }
      device dev_str
      fstype dev_fstype
    end
  end
  node[:elasticsearch][:local_disks].uniq!
end
node.save
