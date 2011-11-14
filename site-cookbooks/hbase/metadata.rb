maintainer       "Chris Howe - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures HBase"



%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "groups/hbase/gid",
  :default               => "304",
  :display_name          => "",
  :description           => ""

attribute "hbase/tmp_dir",
  :default               => "/mnt/tmp/hbase",
  :display_name          => "",
  :description           => ""

attribute "hbase/master_heap_size",
  :default               => "1000m",
  :display_name          => "",
  :description           => ""

attribute "hbase/master_gc_new_size",
  :default               => "256m",
  :display_name          => "",
  :description           => ""

attribute "hbase/master_gc_tuning_opts",
  :default               => "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts",
  :display_name          => "",
  :description           => ""

attribute "hbase/master_gc_log_opts",
  :default               => "-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/var/log/hbase/hbase-master-gc.log",
  :display_name          => "",
  :description           => ""

attribute "hbase/regionserver_heap_size",
  :default               => "2000m",
  :display_name          => "",
  :description           => ""

attribute "hbase/regionserver_gc_new_size",
  :default               => "256m",
  :display_name          => "",
  :description           => ""

attribute "hbase/regionserver_gc_tuning_opts",
  :default               => "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts -XX:CMSInitiatingOccupancyFraction=88",
  :display_name          => "",
  :description           => ""

attribute "hbase/regionserver_gc_log_opts",
  :default               => "-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/var/log/hbase/hbase-regionserver-gc.log",
  :display_name          => "",
  :description           => ""

attribute "hbase/cluster_name",
  :default               => "cluster_name",
  :display_name          => "",
  :description           => ""

attribute "hbase/weekly_backup_tables",
  :display_name          => "",
  :description           => "",
  :default               => ""
