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

%w[ @hadoop @elasticsearch hbase ].each do |usr|
  { 'hard' => ulimit_hard_nofile, 'soft' => ulimit_soft_nofile,  }.each do |limit_type, limit|
    bash "Increase open files #{limit_type} ulimit for #{usr} group" do
      not_if "egrep -q '#{usr}.*#{limit_type}.*nofile.*#{limit}' /etc/security/limits.conf"
      code <<EOF
        egrep -q '#{usr}.*#{limit_type}.*nofile' || ( echo '#{usr} #{limit_type} nofile' >> /etc/security/limits.conf )
        sed -i "s/#{usr}.*#{limit_type}.*nofile.*/#{usr}    #{limit_type}    nofile  #{limit}/" /etc/security/limits.conf
EOF
    end
  end
end



