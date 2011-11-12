default[:server_tuning][:ulimit][:default]         = {}
default[:server_tuning][:ulimit]['@elasticsearch'] = { :nofile => { :both => 32768 }, :nproc => { :both => 50000 } }
