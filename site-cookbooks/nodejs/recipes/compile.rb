#
# Cookbook Name:: nodejs
# Recipe:: default
#
# Copyright 2011, InfoChimps
#
# All rights reserved - Do Not Redistribute
#

include_recipe "python"

package "git"
package "build-essential"

## Replaced by git-specific invocation, below
# execute "git clone nodejs" do
#   cwd "/usr/src"
#   command "git clone #{node.nodejs.git_uri}"
#   creates "/usr/src/node"
# end
git "#{node.nodejs.src_path}" do
  repository "#{node.nodejs.git_uri}"
  reference "master"
  action :sync
end

bash "install nodejs" do
  cwd "#{node.nodejs.src_path}"
  code <<-EOH
  export JOBS=#{node.nodejs.jobs}
  ./configure
  make
  make install
  EOH
  creates "#{node.nodejs.bin_path}"
end
