#
# Cookbook Name::       volumes
# Description::         Build a raid array of volumes as directed by node[:volumes]
# Recipe::              build_raid
# Author::              Chris Howe
#
# Copyright 2011, Infochimps
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

include_recipe 'xfs'

package        'mdadm'

if node[:volumes][:raid_groups]

  # FIXME: Not hard coded
  node[:volumes][:raid_groups] = {
    'md0' => {
      :device => '/dev/md0', :mount_point => '/mnt',
      :from_volumes => %w[ ephemeral0 ]
    }
  }

  node[:volumes][:raid_groups].each do |raid_group, raid_info|

    # FIXME: pull from mountable volumes
    lone_volumes = { :ephemeral0 => { :device => "/dev/sdb", :mount_point => "/mnt" }}

    #
    # unmount all devices tagged for that raid group
    #
    lone_volumes.each do |lone_vol, vol_info|
      mount vol_info[:mount_point] do
        device vol_info[:device]
        action [:umount, :disable]
      end
    end

    # FIXME: "create a raid of all devices tagged for that raid group

    mdadm(raid_info[:device]) do
      devices
      level 0
      action [:create, :assemble]
    end

    script "format #{raid_group}" do
      interpreter "bash"
      user      "root"
      # Returns success iff the drive is formatted XFS
      code      %Q{ mkfs.xfs -f /dev/md0 ; file -s /dev/md0 | grep XFS }
      not_if("file -s /dev/md0 | grep XFS")
    end

    mount raid_info[:mount_point] do
      device     raid_info[:device]
      fstype     raid_info[:fstype]
      options    "nobootwait,comment=cloudconfig"
      action     [:mount, :enable]
    end

  end

end
