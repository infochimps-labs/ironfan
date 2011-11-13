
default[:pig][:home_dir]          = '/usr/lib/pig'

default[:pig][:install_url]       = "http://apache.mirrors.tds.net/pig/pig-0.8.0/pig-0.8.0.tar.gz"
default[:pig][:pig_hbase_patch]   = "https://issues.apache.org/jira/secure/attachment/12466652/pig-0.8.0-hbase-0.89.SNAPSHOT.patch"
default[:pig][:java_home]         = '/usr/lib/jvm/java-6-sun/jre'

default[:pig][:zookeeper_jar_url] = "https://repository.apache.org/content/repositories/releases/org/apache/zookeeper/zookeeper/3.3.1/zookeeper-3.3.1.jar"

default[:pig][:extra_jars]        = [
  "/usr/lib/hbase/hbase-0.90.1-cdh3u0.jar",
  "/usr/lib/hbase/hbase-0.90.1-cdh3u0-tests.jar",
  "/usr/lib/zookeeper/zookeeper.jar",
]
default[:pig][:extra_confs]     = [
  "/etc/hbase/conf/hbase-default.xml",
  "/etc/hbase/conf/hbase-site.xml",
]

default[:pig][:combine_splits]    = "false"
default[:pig][:hbase_conf_dir]    = "fheujahgfyu"
