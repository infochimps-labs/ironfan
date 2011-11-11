overcommit_memory  =     1
overcommit_ratio   =   100
ulimit_hard_nofile = 32768
ulimit_soft_nofile = 32768

def set_proc_sys_limit desc, proc_path, limit
  bash desc do
    not_if{ File.exists?(proc_path) && (File.read(proc_path).chomp.strip == limit.to_s) }
    code  "echo #{limit} > #{proc_path}"
  end
end

set_proc_sys_limit "VM overcommit ratio", '/proc/sys/vm/overcommit_memory', overcommit_memory
set_proc_sys_limit "VM overcommit memory", '/proc/sys/vm/overcommit_ratio',  overcommit_ratio

node[:server_tuning][:ulimit].each do |user, ulimits|
  conf_file = user.gsub(/^@/, 'group_')

  template "/etc/security/limits.d/#{conf_file}.conf" do
    owner "root"
    mode "0644"
    variables({ :user => user, :ulimits => ulimits })
    source "etc_security_limits_overrides.conf.erb"
  end
end
