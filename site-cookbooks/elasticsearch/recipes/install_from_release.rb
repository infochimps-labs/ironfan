# ---------------------------------------------------------------------------
#
# Install elasticsearch
#

# FIXME -- this needs to be done immediately
package "unzip" do
  action :install
end

remote_file "/tmp/elasticsearch-#{node[:elasticsearch][:version]}.zip" do
  source        "https://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-#{node[:elasticsearch][:version]}.zip"
  mode          "0644"
  # checksum      node[:elasticsearch][:checksum]
end

# install into eg. /usr/local/share/elasticsearch-0.x.x ...
directory "#{node[:elasticsearch][:install_dir]}-#{node[:elasticsearch][:version]}" do
  owner       "root"
  group       "root"
  mode        0755
end
# ... and then force /usr/lib/elasticsearch to link to the versioned dir
link node[:elasticsearch][:install_dir] do
  to "#{node[:elasticsearch][:install_dir]}-#{node[:elasticsearch][:version]}"
end

bash "unzip elasticsearch" do
  user          "root"
  cwd           "/tmp"
  code           %(unzip /tmp/elasticsearch-#{node[:elasticsearch][:version]}.zip)
  not_if{ File.exists? "/tmp/elasticsearch-#{node[:elasticsearch][:version]}" }
end

bash "copy elasticsearch root" do
  user          "root"
  cwd           "/tmp"
  code          %(cp -r /tmp/elasticsearch-#{node[:elasticsearch][:version]}/* #{node[:elasticsearch][:install_dir]})
  not_if{ File.exists? "#{node[:elasticsearch][:install_dir]}/lib" }
end
