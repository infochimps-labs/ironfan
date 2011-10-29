#
# Cookbook Name:: rundeck
# Recipe:: default
#
# Copyright 2011, InfoChimps
#


# Compile .deb from github source
  # Download node[:rundeck][:repo]
  # aptitude install pandoc
  # git checkout node[:rundeck][:branch]
  # make clean && make deb
  # dpkg -i packages/rundeck*.deb

package "pandoc"

package "rundeck" do
  
  bash "make rundeck.deb" do
    cwd "/tmp"
    code "git clone #{node[:rundeck][:repo]}
          cd rundeck
          git checkout #{node[:rundeck][:branch]}
          make clean
          make deb"
  end

  provider Chef::Provider::Package::Dpkg
  action :install
  source "/tmp/rundeck/packages/*.deb"
end

# Docco: http://rundeck.org/1.4rc/