#
# Author:: Doug MacEachern <dougm@vmware.com>
# Cookbook Name:: jenkins
# Provider:: cli
#
# Copyright:: 2010, VMware, Inc.
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

def action_run
  url = @new_resource.url || node[:jenkins][:server][:url]
  home = @new_resource.home || node[:jenkins][:node][:home]

  jnlp_jar = node[:jenkins][:node][:cli_jar]
  cli_jar = ::File.join(home, ::File.basename(jnlp_jar))
  remote_cli_jar = "#{url}/#{jnlp_jar}"

  #recipes will chown to jenkins later if this doesn't already exist
  directory "home for #{::File.basename(jnlp_jar)}" do
    action :create
    path node[:jenkins][:node][:home]
  end

  remote_file cli_jar do
    source remote_cli_jar
    mode "0644"
    backup false
    action :nothing
  end

  http_request "HEAD /#{jnlp_jar}" do
    message ""
    url remote_cli_jar
    action :head
    if ::File.exists?(cli_jar)
      headers "If-Modified-Since" => ::File.mtime(cli_jar).httpdate
    end
    notifies :create, resources(:remote_file => cli_jar), :immediately
  end

  java_home = node[:jenkins][:java_home] || (node.has_key?(:java) ? node[:java][:jdk_dir] : nil)
  if java_home == nil
    java = "java"
  else
    java = ::File.join(java_home, "bin", "java")
  end

  command = "#{java} -jar #{cli_jar} -s #{url} #{@new_resource.command}"

  jenkins_execute command do
    cwd home
    block { |stdout| new_resource.block.call(stdout) } if new_resource.block
    only_if new_resource.only_if
  end
end
