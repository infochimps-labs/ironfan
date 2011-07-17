group("redis"){ gid 335 }
user "redis" do
  comment   "Redis-server runner"
  uid       335
  gid       "redis"
  shell     "/bin/false"
end

directory "/var/log/redis" do
  owner     "redis"
  group     "redis"
  mode      "0755"
  action    :create
end

directory node[:redis][:dbdir] do
  owner     "redis"
  group     "redis"
  mode      "0755"
  action    :create
  recursive true
end

directory "/etc/redis" do
  owner     "root"
  group     "root"
  mode      "0755"
  action    :create
end
