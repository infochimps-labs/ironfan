def user_is_in_role?(username)
  return false if !@node[:role]
  Chef::Log.info role[:groups].inspect
  role[:groups].include? get_user(username)[:group]
end

def role
  @node[:roles][@node[:role]]
end

# method name 'user' conflicts with chef, so we use 'get_user'
def get_user(username)
  Chef::Log.info username
  user = @node[:users][username]
  Chef::Log.info user.inspect
  user
end
