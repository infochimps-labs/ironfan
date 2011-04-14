#
# Add the Cassandra CLI tools to the system path
#

template "/etc/profile.d/cassandra_tools.sh" do
  source "cassandra_tools.sh.erb"
  owner "root"
  mode 0644
end
