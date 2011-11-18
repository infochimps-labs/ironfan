#
# Cookbook Name::       nodejs
# Description::         Compile
# Recipe::              compile
# Author::              Nathaniel Eliot - Infochimps, Inc
#
# Copyright 2011, Infochimps
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

include_recipe "python"

package "git"
package "build-essential"

## Replaced by git-specific invocation, below
# execute "git clone nodejs" do
#   cwd "/usr/src"
#   command "git clone #{node[:nodejs][:git_repo]}"
#   creates "/usr/src/node"
# end
git "#{node[:nodejs][:install_dir]}" do
  repository "#{node[:nodejs][:git_repo]}"
  reference "master"
  action :sync
end

bash "install nodejs" do
  cwd "#{node[:nodejs][:install_dir]}"
  code <<-EOH
  export JOBS=#{node[:nodejs][:jobs]}
  ./configure
  make
  make install
  EOH
  creates "#{node[:nodejs][:bin_path]}"
end
