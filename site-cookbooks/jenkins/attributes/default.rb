#
# Cookbook Name:: jenkins
# Based on hudson
# Attributes:: default
#
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright 2010, VMware, Inc.
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


# default[:jenkins][:mirror]       = "http://updates.jenkins-ci.org"
default[:jenkins][:apt_mirror]     = "http://pkg.jenkins-ci.org/debian"
default[:jenkins][:plugins_mirror] = "http://updates.jenkins-ci.org"
default[:jenkins][:java_home] = ENV['JAVA_HOME']

default[:jenkins][:server][:home] = "/var/lib/jenkins"
default[:jenkins][:server][:user] = "jenkins"

case node[:platform]
when "debian", "ubuntu"
  default[:jenkins][:server][:group] = "nogroup"
else
  default[:jenkins][:server][:group] = node[:jenkins][:server][:user]
end

default[:jenkins][:server][:port]    = 8080
default[:jenkins][:server][:host]    = node[:fqdn]

default[:jenkins][:server][:jvm_heap] = 384

default[:jenkins][:iptables_allow] = "enable"

#download the latest version of plugins, bypassing update center
#example: ["git", "URLSCM", ...]
default[:jenkins][:server][:plugins] = []

# working around: http://tickets.opscode.com/browse/CHEF-1848; set to true if you have the CHEF-1848 patch applied
default[:jenkins][:server][:use_head] = false


#See Jenkins >> Nodes >> $name >> Configure

#"Name"
default[:jenkins][:node][:name]    = node[:fqdn]

#"Description"
default[:jenkins][:node][:description] =
  "#{node[:platform]} #{node[:platform_version]} " <<
  "[#{node[:kernel][:os]} #{node[:kernel][:release]} #{node[:kernel][:machine]}] " <<
  "slave on #{node[:hostname]}"

#"# of executors"
default[:jenkins][:node][:executors] = 1

#"Remote FS root"
if node[:os] == "windows"
  default[:jenkins][:node][:home] = "C:/jenkins"
elsif node[:os] == "darwin"
  default[:jenkins][:node][:home] = "/Users/jenkins"
else
  default[:jenkins][:node][:home] = "/var/lib/jenkins-node"
end

#"Labels"
default[:jenkins][:node][:labels] = (node[:tags] || []).join(" ")

#"Usage"
#  "Utilize this slave as much as possible" -> "normal"
#  "Leave this machine for tied jobs only"  -> "exclusive"
default[:jenkins][:node][:mode] = "normal"

#"Launch method"
#  "Launch slave agents via JNLP"                        -> "jnlp"
#  "Launch slave via execution of command on the Master" -> "command"
#  "Launch slave agents on Unix machines via SSH"         -> "ssh"
if node[:os] == "windows"
  default[:jenkins][:node][:launcher] = "jnlp"
else
  default[:jenkins][:node][:launcher] = "ssh"
end

#"Availability"
#  "Keep this slave on-line as much as possible"                   -> "always"
#  "Take this slave on-line when in demand and off-line when idle" -> "demand"
default[:jenkins][:node][:availability] = "always"

#  "In demand delay"
default[:jenkins][:node][:in_demand_delay] = 0
#  "Idle delay"
default[:jenkins][:node][:idle_delay] = 1

#"Node Properties"
#[x] "Environment Variables"
default[:jenkins][:node][:env] = nil

default[:jenkins][:node][:user] = "jenkins-node"

#SSH options
default[:jenkins][:node][:ssh_host] = node[:fqdn]
default[:jenkins][:node][:ssh_port] = 22
default[:jenkins][:node][:ssh_user] = default[:jenkins][:node][:user]
default[:jenkins][:node][:ssh_pass] = nil
default[:jenkins][:node][:jvm_options] = nil
#jenkins master defaults to: "#{ENV['HOME']}/.ssh/id_rsa"
default[:jenkins][:node][:ssh_private_key] = nil

default[:jenkins][:http_proxy][:variant]              = nil
default[:jenkins][:http_proxy][:www_redirect]         = "disable"
default[:jenkins][:http_proxy][:listen_ports]         = [ 80 ]
default[:jenkins][:http_proxy][:host_name]            = nil
default[:jenkins][:http_proxy][:host_aliases]         = []
default[:jenkins][:http_proxy][:client_max_body_size] = "1024m"
