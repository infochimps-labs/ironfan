maintainer       "Chris Howe - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures HBase"

depends          "java"
depends          "apt"
depends          "hadoop_cluster"
depends          "zookeeper"
depends          "ganglia"
depends          "mountable_volumes"
depends          "provides_service"

recipe           "hbase::backup_tables",               "Cron job to backup tables to S3"
recipe           "hbase::default",                     "Base configuration for hbase"
recipe           "hbase::master",                "HBase Master"
recipe           "hbase::regionserver",          "HBase Regionserver"
recipe           "hbase::stargate",                    "HBase Stargate: HTTP frontend to HBase"
recipe           "hbase::add_cloudera_repo",           "Add Cloudera repo to package manager"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "apt/cloudera/force_distro",
  :display_name          => "Override the distro name apt uses to look up repos",
  :description           => "Typically, leave this blank. However if (as is the case in Nov 2011) you are on natty but Cloudera's repo only has packages up to maverick, use this to override.",
  :default               => ""

attribute "apt/cloudera/release_name",
  :display_name          => "Release identifier (eg cdh3u2) of the cloudera repo to use. See also hadoop/deb_version",
  :description           => "Release identifier (eg cdh3u2) of the cloudera repo to use. See also hadoop/deb_version",
  :default               => "cdh3u2"

attribute "groups/hbase/gid",
  :display_name          => "",
  :description           => "",
  :default               => "304"

attribute "hbase/tmp_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/mnt/tmp/hbase"

attribute "hbase/master/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => "1000m"

attribute "hbase/master/gc_new_size",
  :display_name          => "",
  :description           => "",
  :default               => "256m"

attribute "hbase/master/gc_tuning_opts",
  :display_name          => "",
  :description           => "",
  :default               => "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts"

attribute "hbase/master/gc_log_opts",
  :display_name          => "",
  :description           => "",
  :default               => "-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/var/log/hbase/hbase-master-gc.log"

attribute "hbase/regionserver/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => "2000m"

attribute "hbase/regionserver/gc_new_size",
  :display_name          => "",
  :description           => "",
  :default               => "256m"

attribute "hbase/regionserver/gc_tuning_opts",
  :display_name          => "",
  :description           => "",
  :default               => "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts -XX:CMSInitiatingOccupancyFraction=88"

attribute "hbase/regionserver/gc_log_opts",
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
