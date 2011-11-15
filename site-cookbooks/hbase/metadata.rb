maintainer       "Chris Howe - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures HBase"

depends          "java"
depends          "apt"
depends          "mountable_volumes"
depends          "provides_service"
depends          "hadoop_cluster"
depends          "zookeeper"
depends          "ganglia"

recipe           "hbase::backup_tables",               "Backup Tables"
recipe           "hbase::default",                     "Default"
recipe           "hbase::hbase_master",                "Hbase Master"
recipe           "hbase::hbase_regionserver",          "Hbase Regionserver"
recipe           "hbase::master",                      "Master"
recipe           "hbase::regionserver",                "Regionserver"
recipe           "hbase::stargate",                    "Stargate"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "groups/hbase/gid",
  :display_name          => "",
  :description           => "",
  :default               => "304"

attribute "hbase/tmp_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/mnt/tmp/hbase"

attribute "hbase/master_heap_size",
  :display_name          => "",
  :description           => "",
  :default               => "1000m"

attribute "hbase/master_gc_new_size",
  :display_name          => "",
  :description           => "",
  :default               => "256m"

attribute "hbase/master_gc_tuning_opts",
  :display_name          => "",
  :description           => "",
  :default               => "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts"

attribute "hbase/master_gc_log_opts",
  :display_name          => "",
  :description           => "",
  :default               => "-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/var/log/hbase/hbase-master-gc.log"

attribute "hbase/regionserver_heap_size",
  :display_name          => "",
  :description           => "",
  :default               => "2000m"

attribute "hbase/regionserver_gc_new_size",
  :display_name          => "",
  :description           => "",
  :default               => "256m"

attribute "hbase/regionserver_gc_tuning_opts",
  :display_name          => "",
  :description           => "",
  :default               => "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts -XX:CMSInitiatingOccupancyFraction=88"

attribute "hbase/regionserver_gc_log_opts",
  :display_name          => "",
  :description           => "",
  :default               => "-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/var/log/hbase/hbase-regionserver-gc.log"

attribute "hbase/cluster_name",
  :display_name          => "",
  :description           => "",
  :default               => "cluster_name"

attribute "hbase/weekly_backup_tables",
  :display_name          => "",
  :description           => "",
  :default               => ""
