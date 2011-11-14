#
# Cookbook Name::       mountable_volumes
# Recipe::              mount
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2011, Philip (flip) Kromer - Infochimps, Inc
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

mountable_volumes.each do |vol_name, vol|
  
  if File.exists?(vol['device'])
    directory vol['mount_point'] do
      recursive true
      owner( vol['owner'] || 'root' )
      group( vol['owner'] || 'root' )
    end

    #
    # If you mount multiple EBS volumes from the same snapshot, you may get an
    #   'XFS: Filesystem xvdk has duplicate UUID - can't mount'
    # error (check `sudo dmesg | tail`).
    #
    # If so, read http://linux-tips.org/article/50/xfs-filesystem-has-duplicate-uuid-problem
    #
    
    mount vol['mount_point'] do
      only_if{ File.exists?(vol['device']) }
      device    vol['device']
      fstype    vol['fs_type']       || fstype_from_file_magic(vol['device'])
      options   vol['mount_options'] || 'defaults'
      action    [:mount]
    end
  else
    Chef::Log.info "Before mounting, you must attach volume #{vol_name} to this instance (#{node[:ec2][:instance_id]}) at #{vol['device']}"
  end
  
end
