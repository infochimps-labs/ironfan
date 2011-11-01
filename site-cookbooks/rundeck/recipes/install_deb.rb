#
# Cookbook Name:: rundeck
# Recipe:: default
#
# Copyright 2011, InfoChimps
#

# Download and install the rundeck deb, given the address of a build
cache = "/tmp/rundeck.deb"
remote_file cache do
  source node[:rundeck][:deb]
end
package "rundeck" do
  source cache
  provider Chef::Provider::Package::Dpkg
  action :install
end

# rebuild the user table: replace admin user with array of users in group admin

# set up a default project