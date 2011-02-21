#
# Cookbook Name:: hadoop
# Recipe:: hadoop_webfront
#

#
# Make a quickie little web server to
# let you easily jump to the namenode, jobtracker or cloudera_desktop
#

package 'thttpd'

case node[:platform]
when 'debian', 'ubuntu'    then www_base = '/var/www'             # debian-ish
else                            www_base = '/var/www/thttpd/html' # redhat-ish
end

template "#{www_base}/index.html" do
  owner "root"
  mode "0644"
  source "webfront_index.html.erb"
end

execute "Enable thttpd" do
  command %Q{sed -i -e 's|ENABLED=no|ENABLED=yes|' /etc/default/thttpd}
  not_if "grep 'ENABLED=yes' '/etc/default/thttpd'"
end

service "thttpd" do
  action [ :start, :enable ]
end
