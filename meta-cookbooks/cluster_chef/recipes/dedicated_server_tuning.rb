#
# Cookbook Name::       cluster_chef
# Description::         Dedicated Server Tuning
# Recipe::              dedicated_server_tuning
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

overcommit_memory  =     1
overcommit_ratio   =   100
ulimit_hard_nofile = 32768
ulimit_soft_nofile = 32768

def set_proc_sys_limit desc, proc_path, limit
  bash desc do
    not_if{ File.exists?(proc_path) && (File.read(proc_path).chomp.strip == limit.to_s) }
    code  "echo #{limit} > #{proc_path}"
  end
end

set_proc_sys_limit "VM overcommit ratio", '/proc/sys/vm/overcommit_memory', overcommit_memory
set_proc_sys_limit "VM overcommit memory", '/proc/sys/vm/overcommit_ratio',  overcommit_ratio

node[:server_tuning][:ulimit].each do |user, ulimits|
  conf_file = user.gsub(/^@/, 'group_')

  template "/etc/security/limits.d/#{conf_file}.conf" do
    owner "root"
    mode "0644"
    variables({ :user => user, :ulimits => ulimits })
    source "etc_security_limits_overrides.conf.erb"
  end
end
