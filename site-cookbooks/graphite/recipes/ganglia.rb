#
# Cookbook Name::       graphite
# Recipe::              ganglia
# Author::              Heavy Water Software Inc.
#
# Copyright 2011, Heavy Water Software Inc.
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

include_recipe "graphite"
include_recipe "ganglia::gmetad"

target = "/opt/graphite/storage/rrd/#{node.ganglia.cluster_name}"

directory target do
  mode "755"
end

Dir.glob("/var/lib/ganglia/rrds/#{node.ganglia.cluster_name}/*.*").each do |path|
  source = File.basename(path).gsub(".", "_")
  link "#{target}/#{source}" do
    to path
  end
end
