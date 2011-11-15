default[:pig][:home_dir]          = '/usr/lib/pig'

default[:pig][:install_url]       = "http://apache.mirrors.tds.net/pig/pig-0.9.1/pig-0.9.1.tar.gz"
default[:pig][:java_home]         = '/usr/lib/jvm/java-6-sun/jre'

default[:pig][:extra_jars]        = [
  "/usr/lib/hbase/hbase-0.90.1-cdh3u0.jar",
  "/usr/lib/hbase/hbase-0.90.1-cdh3u0-tests.jar",
  "/usr/lib/zookeeper/zookeeper.jar",
]
default[:pig][:extra_confs]     = [
  "/etc/hbase/conf/hbase-default.xml",
  "/etc/hbase/conf/hbase-site.xml",
]

default[:pig][:combine_splits]    = "true"
