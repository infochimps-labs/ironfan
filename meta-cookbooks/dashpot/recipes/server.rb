#
# Cookbook Name::       dashpot
# Description::         Lightweight thttpd server to render dashpot dashboards
# Recipe::              server
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

include_recipe  'dashpot'
include_recipe  'runit'

#
# Lightweight THTTPD server
#

package         'thttpd'
package         'thttpd-util'

template "#{node[:dashpot][:conf_dir]}/dashboard-thttpd.conf" do
  owner         "root"
  mode          "0644"
  source        "dashboard-thttpd.conf.erb"
end

runit_service "dashpot_dashboard" do
  run_state     node[:dashpot][:run_state]
  options       node[:dashpot]
end
