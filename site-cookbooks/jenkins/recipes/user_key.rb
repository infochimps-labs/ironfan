pkey = "#{node[:jenkins][:server][:home]}/.ssh/id_rsa"

user node[:jenkins][:server][:user] do
  home      node[:jenkins][:server][:home]
end

directory node[:jenkins][:server][:home] do
  recursive true
  owner     node[:jenkins][:server][:user]
  group     node[:jenkins][:server][:group]
end

directory "#{node[:jenkins][:server][:home]}/.ssh" do
  mode      "0700"
  owner     node[:jenkins][:server][:user]
  group     node[:jenkins][:server][:group]
  recursive true
  action    :create
end

execute "ssh-keygen -f #{pkey} -N ''" do
  user  node[:jenkins][:server][:user]
  group node[:jenkins][:server][:group]
  not_if { File.exists?(pkey) }
end

ruby_block "store jenkins ssh pubkey" do
  block do
    node.set[:jenkins][:server][:pubkey] = File.open("#{pkey}.pub") { |f| f.gets }
  end
end

Chef::Log.info ['pubkey', __FILE__]
