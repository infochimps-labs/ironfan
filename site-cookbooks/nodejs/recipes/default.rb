#
# Cookbook Name:: nodejs
# Recipe:: default
#
# Copyright 2011, InfoChimps
#
# All rights reserved - Do Not Redistribute
#

include_recipe "python"

package "python-software-properties"

execute "setup PPA for nodejs install" do
    command "add-apt-repository ppa:jerome-etienne/neoip && aptitude update"
end

package "nodejs"