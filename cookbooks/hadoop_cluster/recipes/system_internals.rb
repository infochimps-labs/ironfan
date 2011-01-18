overcommit_memory  =     1
overcommit_ratio   =   100
ulimit_hard_nofile = 32768
ulimit_soft_nofile = 32768
fs_epoll_max_user_instances = 4096

def set_proc_sys_limit desc, proc_path, limit
  bash desc do
    not_if{ File.exists?(proc_path) && (File.read(proc_path).chomp.strip == limit.to_s) }
    code  "echo #{limit} > #{proc_path}"
  end
end

set_proc_sys_limit "VM overcommit ratio", '/proc/sys/vm/overcommit_memory', overcommit_memory
set_proc_sys_limit "VM overcommit memory", '/proc/sys/vm/overcommit_ratio',  overcommit_ratio


# recent kernels do away with this limit, so these lines aren't necessary.
# # http://pero.blogs.aprilmayjune.org/2009/01/22/hadoop-and-linux-kernel-2627-epoll-limits/
# set_proc_sys_limit "Increase epoll instances limit", '/proc/sys/fs/epoll/max_user_instances', fs_epoll_max_user_instances


bash "Increase open files hard ulimit for @hadoop group" do
  not_if "egrep -q 'hbase.*hard.*nofile.*#{ulimit_hard_nofile}' /etc/security/limits.conf"
  code <<EOF
    egrep -q '@hadoop.*hard.*nofile' || ( echo '@hadoop hard nofile' >> /etc/security/limits.conf )
    sed -i "s/@hadoop.*hard.*nofile.*/@hadoop    hard    nofile  #{ulimit_hard_nofile}/" /etc/security/limits.conf
    egrep -q 'hbase.*hard.*nofile' || ( echo 'hbase   hard nofile' >> /etc/security/limits.conf )
    sed -i "s/hbase.*hard.*nofile.*/hbase      hard    nofile  #{ulimit_hard_nofile}/" /etc/security/limits.conf
EOF
end

bash "Increase open files soft ulimit for @hadoop group" do
  not_if "egrep -q '@hadoop.*soft.*nofile.*#{ulimit_soft_nofile}' /etc/security/limits.conf"
  code <<EOF
    egrep -q '@hadoop.*soft.*nofile' || ( echo '@hadoop soft nofile' >> /etc/security/limits.conf )
    sed -i "s/@hadoop.*soft.*nofile.*/@hadoop    soft    nofile  #{ulimit_soft_nofile}/" /etc/security/limits.conf
    egrep -q 'hbase.*soft.*nofile' || ( echo 'hbase   soft nofile' >> /etc/security/limits.conf )
    sed -i "s/hbase.*soft.*nofile.*/hbase      soft    nofile  #{ulimit_soft_nofile}/" /etc/security/limits.conf
EOF
end


