#
# Cookbook Name::       firewall
# Description::         Port Scan
# Recipe::              port_scan
# Author::              Mike Heffner
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

include_recipe 'iptables'

(node[:firewall][:port_scan] || {}).each do |svc, info|
  iptables_rule "no_port_scan_#{svc}" do
    source "no_port_scan.erb"
    variables({
        :name      => svc,
        :port      => info[:port],
        :max_conns => info[:max_conns],
        :window    => info[:window],
      })
  end
end
