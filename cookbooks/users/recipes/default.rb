node[:groups].each do |group_key, config|
  group group_key do
    group_name group_key.to_s
    gid        config[:gid]
    action     [:create]
    not_if{ node[:etc][:group][group_key.to_s] }
  end
end

if node[:active_users]
  node[:active_users].each do |uname|
    config = node[:users][uname] or next
    user uname do
      comment   config[:comment]
      # uid       config[:uid]
      # gid       config[:groups].first
      home      "/home/#{uname}"
      shell     "/bin/bash"
      # password  config[:password]
      supports  :manage_home => true
      action    [:create, :manage]
    end

    directory "/home/#{uname}/.ssh" do
      action    :create
      owner     uname
      group     config[:groups].first.to_s
      mode      0700
    end

    config[:groups].each do |gname|
      group gname do
        group_name gname.to_s
        members    [ uname ]
        append     true
        action     [:manage]
      end
    end

  end
end
