#
# Cookbook Name::       metachef
# Description::         Dedicated Server Tuning
# Recipe::              ubuntu
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

def set_proc_sys_limit desc, proc_path, limit
  bash "set #{desc} to #{limit}" do
    only_if{ File.exists?(proc_path) }
    not_if{  File.read(proc_path).chomp.strip == limit.to_s }
    code     "echo #{limit} > #{proc_path}"
  end
end

set_proc_sys_limit "VM overcommit ratio",  '/proc/sys/vm/overcommit_memory', node[:tuning][:overcommit_memory]
set_proc_sys_limit "VM overcommit memory", '/proc/sys/vm/overcommit_ratio',  node[:tuning][:overcommit_ratio]
set_proc_sys_limit "VM swappiness",        '/proc/sys/vm/swappiness',        node[:tuning][:swappiness]

node[:tuning][:ulimit].each do |user, ulimits|
  conf_file = user.gsub(/^@/, 'group_')

  template "/etc/security/limits.d/#{conf_file}.conf" do
    owner "root"
    mode "0644"
    variables({ :user => user, :ulimits => ulimits })
    source "etc_security_limits_overrides.conf.erb"
  end
end
