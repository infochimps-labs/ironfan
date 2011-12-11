STANDARD_DIRS = Mash.new({
  :home_dir  => { :uid => 'root', :gid => 'root', },
  :conf_dir  => { :uid => 'root', :gid => 'root', },
  :lib_dir   => { :uid => 'root', :gid => 'root', },
  :log_dir   => { :uid => :user,  :gid => :group, :mode => "0775", },
  :pid_dir   => { :uid => :user,  :gid => :group, },
  :tmp_dir   => { :uid => :user,  :gid => :group, },
  :data_dir  => { :uid => :user,  :gid => :group, },
  :data_dirs => { :uid => :user,  :gid => :group, },
  :cache_dir => { :uid => :user,  :gid => :group, },
}) unless defined?(STANDARD_DIRS)

#
# If present, we will use node[(name)][(subsys)] *and then* node[(name)] to
# look up scoped default values.
#
# So, daemon_user('ntp') looks for its :log_dir in node[:ntp][:log_dir], while
# daemon_user('ganglia.server') looks first in node[:ganglia][:server][:log_dir]
# and then in node[:ganglia][:log_dir].
#
define(:standard_dirs,
  :subsys      => nil, # if present, will use node[(name)][(subsys)] *and then* node[(name)] to look up values.
  :directories => [],
  :log_dir     => nil,
  :home_dir    => nil,
  :user        => nil, # username to create.      default: `scoped_hash[:user]`
  :group       => nil  # group for user.          default: `scoped_hash[:group]`
  ) do

  sys, subsys = params[:name].to_s.split(".", 2).map(&:to_sym)
  component = ClusterChef::Component.new(node, sys, subsys)

  params[:user]       ||= component.node_attr(:user, :required)
  params[:group]      ||= component.node_attr(:group) || params[:user]

  [params[:directories]].flatten.each do |dir_type|
    dir_paths = component.node_attr(dir_type, :required) or next
    hsh = (STANDARD_DIRS.include?(dir_type) ? STANDARD_DIRS[dir_type].dup : Mash.new)
    hsh[:uid] = params[:user]  if (hsh[:uid] == :user )
    hsh[:gid] = params[:group] if (hsh[:gid] == :group)
    [dir_paths].flatten.each do |dir_path|
      directory dir_path do
        owner       hsh[:uid]
        group       hsh[:gid]
        mode        hsh[:mode] || '0755'
        action      :create
        recursive   true
      end
    end
  end

end
