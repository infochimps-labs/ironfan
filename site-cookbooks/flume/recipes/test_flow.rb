#
# Cookbook Name::       flume
# Description::         Test Flow
# Recipe::              test_flow
# Author::              Chris Howe - Infochimps, Inc
#
# Copyright 2011, Chris Howe - Infochimps, Inc
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

flume_logical_node "magic" do
  source        "console"
  sink          "console"
  flow          "test_flow"
  physical_node node[:fqdn]
  flume_master  discover(:flume, :master).private_ip
  action        [:spawn,:config]
end
