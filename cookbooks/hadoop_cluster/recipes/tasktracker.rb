#
# Just run a tasktracker, no datanode
#
include_recipe "hadoop_cluster"

package "#{node[:hadoop][:hadoop_handle]}-tasktracker"

%w{tasktracker}.each do |d|
  service "#{node[:hadoop][:hadoop_handle]}-#{d}" do
    action [ :enable, :start ]
    running true
    supports :status => true, :restart => true
  end
end
