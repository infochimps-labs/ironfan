#
# Just run a tasktracker, no datanode
#
include_recipe "hadoop_cluster"

package "#{node[:hadoop][:hadoop_handle]}-tasktracker" do
  version "0.20.2+320-1~lucid-cdh3b2"
end


%w{tasktracker}.each do |d|
  service "#{node[:hadoop][:hadoop_handle]}-#{d}" do
    action [ :enable, :start ]
    running true
    supports :status => true, :restart => true
  end
end
