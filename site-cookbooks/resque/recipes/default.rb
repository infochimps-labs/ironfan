#
# Install
#

%w[
  thin rack resque redis redis-namespace yajl-ruby
].each{|gem_name| gem_package gem_name }

directory node[:resque][:dir]+'/..' do
  owner     'root'
  group     'root'
  mode      "0775"
  recursive true
  action    :create
end

#
# User
#
group 'resque' do gid 336 ; action [:create] ; end
user 'resque' do
  comment    'Resque queue user'
  uid        336
  group      'resque'
  home       node[:resque][:dir]
  shell      "/bin/false"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

#
# Directories
#
[ :log_dir, :tmp_dir, :dbdir, :swapdir, :conf_dir  ].each do |dirname|
  directory node[:resque][dirname] do
    owner     node[:resque][:user]
    group     node[:resque][:group]
    mode      "0775"
    recursive true
    action    :create
  end
end


