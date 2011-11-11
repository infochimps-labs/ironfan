
default[:server_tuning][:ulimit]['hdfs']           = { :nofile => { :both => 32768 }, :nproc => { :both => 50000 } }
default[:server_tuning][:ulimit]['hbase']          = { :nofile => { :both => 32768 }, :nproc => { :both => 50000 } }
default[:server_tuning][:ulimit]['mapred']         = { :nofile => { :both => 32768 }, :nproc => { :both => 50000 } }
default[:server_tuning][:ulimit]['@hadoop']        = { :nofile => { :both => 32768 }, :nproc => { :both => 50000 } }
