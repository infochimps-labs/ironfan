#
# Cookbook Name:: hadoop
# Recipe:: munge_system_limits
#

#
# Adjust system limits according to the recommendations in
#
#   http://www.cloudera.com/blog/2009/03/configuration-parameters-what-can-you-just-ignore/
#

# NOT TESTED YET

# # into   /etc/security/limits.conf
# # insert hadoop hard nofile 16384
# bash "up the file descriptor limit" do
#   user 'root'
#   code "echo 'hadoop hard nofile 16384' >> /etc/security/limits.conf"
#   not_if "egrep 'hadoop hard nofile' /etc/security/limits.conf"
# end

# into   /proc/sys/fs/epoll/max_user_instances
# insert 4096

# into   /etc/sysctl.conf
# insert fs.epoll.max_user_instances = 4096
