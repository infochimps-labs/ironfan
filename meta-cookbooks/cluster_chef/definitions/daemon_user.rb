
#
# If present, we will use node[(name)][(component)] *and then* node[(name)] to
# look up scoped default values.
#
# So, daemon_user('ntp') looks for a username in node[:ntp][:user], while
# daemon_user('ganglia.server') looks first in node[:ganglia][:server][:user]
# and then in node[:ganglia][:user].
#
define(:daemon_user,
  :action       => [:create, :manage],  # action. You typically want [:create, :manage] or [:create]
  :component    => nil,                 # if present, will use node[(name)][(component)] *and then* node[(name)] to look up values.
  :user         => nil,                 # username to create.      default: `scoped_hash[:user]`
  :home         => nil,                 # home directory for daemon. default: `scoped_hash[:pid_dir]`
  :group        => nil,                 # group for daemon.          default: `scoped_hash[:group]`
  :comment      => nil,                 # comment for user info
  :create_group => true                 # Action to take on the group: `true` means `[:create]`, false-y means do nothing, or you can supply explicit actions (eg `[:create, :manage]`). default: true
  ) do

  sys, subsys = params[:name].to_s.split(".", 2).map(&:to_sym)
  component = ClusterChef::Component.new(node, sys, subsys)

  params[:user]         ||= component.node_attr(:user, :required)
  params[:group]        ||= component.node_attr(:group) || params[:user]
  params[:home]         ||= component.node_attr(:pid_dir, :required)
  params[:comment]      ||= "#{component.name} daemon"
  #
  user_val                = params[:user].to_s
  group_val               = params[:group].to_s
  uid_val                 = node[:users ][user_val ] && node[:users ][user_val ][:uid]
  gid_val                 = node[:groups][group_val] && node[:groups][group_val][:gid]
  #
  params[:create_group]   = [:create] if (params[:create_group] == true)
  params[:create_group]   = false     if (group_val == 'nogroup')

  #
  # Make the group
  #
  if params[:create_group] && (group_val != 'nogroup')
    group group_val do
      gid       gid_val
      action    params[:create_group]
    end
  end

  #
  # Make the user
  #
  user user_val do
    uid           uid_val
    gid           group_val
    password      nil
    shell         '/bin/false'
    home          params[:home]
    supports      :manage_home => false # you must create standard dirs yourself
    action        params[:action]
  end

end
