#
# Cookbook Name::       elasticsearch
# Description::         Build Raid
# Recipe::              build_raid
# Author::              GoTime, modifications by Infochimps
#
# Copyright 2011, GoTime, modifications by Infochimps
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

package 'mdadm'

if node[:elasticsearch][:raid][:use_raid]

  mount "/mnt" do
    device "/dev/sdb"
    action [:umount, :disable]
  end
  
  mdadm "/dev/md0" do
    devices node[:elasticsearch][:raid][:devices]
    level 0
    action [:create, :assemble]
  end
  
  script "format_md0_xfs" do
    interpreter "bash"
    user "root"
    code <<-EOH
    if (! (file -s /dev/md0 | grep XFS) ); then
        mkfs.xfs -f /dev/md0
    fi
    # Returns success iff the drive is formatted XFS
    file -s /dev/md0 | grep XFS
    EOH
  end
  
  mount "/mnt" do
    device "/dev/md0"
    fstype "xfs"
    options "nobootwait,comment=cloudconfig"
    action [:mount, :enable]
  end

end
