maintainer       "Chris Howe - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "HBase: a massively-scalable high-throughput datastore based on the Hadoop HDFS"

depends          "java"
depends          "apt"
depends          "runit"

depends          "volumes"
depends          "metachef"

depends          "hadoop_cluster"
depends          "zookeeper"
depends          "ganglia"

recipe           "hbase::backup_tables",               "Cron job to backup tables to S3"
recipe           "hbase::default",                     "Base configuration for hbase"
recipe           "hbase::master",                      "HBase Master"
recipe           "hbase::regionserver",                "HBase Regionserver"
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
  :default               => "/mnt/hbase/tmp"

attribute "hbase/cluster_name",
  :display_name          => "",
  :description           => "",
  :default               => "cluster_name"

attribute "hbase/weekly_backup_tables",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hbase/home_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/lib/hbase"

attribute "hbase/conf_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/etc/hbase/conf"

attribute "hbase/log_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/var/log/hbase"

attribute "hbase/pid_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/var/run/hbase"

attribute "hbase/exported_confs",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["/hbase-default.xml", "/hbase-site.xml"]

attribute "hbase/exported_jars",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["/usr/lib/hbase/hbase-0.90.1-cdh3u0.jar", "/usr/lib/hbase/hbase-0.90.1-cdh3u0-tests.jar"]

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

attribute "hbase/master/run_state",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => "start"

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

attribute "hbase/regionserver/run_state",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => "start"

attribute "hbase/stargate/run_state",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => "start"

attribute "hbase/thrift/run_state",
  :display_name          => "",
  :description           => "",
  :default               => "start"
