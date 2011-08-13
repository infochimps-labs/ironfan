#
# Author:: Mike Heffner (<mike@librato.com>)
# Cookbook Name:: cassandra
# Recipe:: authentication
#
# Handles authentication and authority configuration.
#
# Looks for a databag named 'cassandra', with the id 'clusters' and
# a key of <cluster name> like:
#
#   {:id : "clusters",
#     {<cluster name> => {
#       :authentication => {
#          :use_md5 => true|false
#          :users => [
#             [name, passwd (plain or in md5)],
#             ....
#          ]
#       },
#       :authority => {
#          "keyspace" => {
#             "CF ('_' for none)" => {
#                "rw/ro" => [username1, username2, ...]
#             }
#          }
#       }}}
#
#

clusters = data_bag_item('cassandra', 'clusters') rescue nil
return unless clusters

cluster = clusters[node[:cassandra][:cluster_name]]
return unless cluster

auth = cluster['authentication']
if auth
  node[:cassandra][:authenticator] = "org.apache.cassandra.auth.SimpleAuthenticator"
  if auth['use_md5']
    node[:cassandra][:passwd_use_md5] = true
  end

  node[:cassandra][:passwd_properties] = "#{node[:cassandra][:cassandra_conf]}/passwd.properties"
  template "#{node[:cassandra][:cassandra_conf]}/passwd.properties" do
    source "passwd.properties.erb"
    owner node[:cassandra][:cassandra_user]
    mode 0600
    variables({:users => auth['users']})
    notifies  :restart, resources(:service => "cassandra")
  end
end

access = cluster['authority']
if access
  node[:cassandra][:authority] = "org.apache.cassandra.auth.SimpleAuthority"

  node[:cassandra][:access_properties] = "#{node[:cassandra][:cassandra_conf]}/access.properties"
  template "#{node[:cassandra][:cassandra_conf]}/access.properties" do
    source "access.properties.erb"
    owner node[:cassandra][:cassandra_user]
    mode 0600
    variables({:acls => access})
    notifies  :restart, resources(:service => "cassandra")
  end
end
