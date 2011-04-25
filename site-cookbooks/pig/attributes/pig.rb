default[:pig][:install_url]       = "http://apache.mirrors.tds.net/pig/pig-0.8.0/pig-0.8.0.tar.gz"
default[:pig][:pig_hbase_patch]   = "https://issues.apache.org/jira/secure/attachment/12466652/pig-0.8.0-hbase-0.89.SNAPSHOT.patch"
default[:pig][:java_home]         = '/usr/lib/jvm/java-6-sun/jre'
default[:pig][:zookeeper_jar_url] = "https://repository.apache.org/content/repositories/releases/org/apache/zookeeper/zookeeper/3.3.1/zookeeper-3.3.1.jar"
default[:pig][:zookeeper_jars]    = ["zookeeper.jar"]
default[:pig][:hbase_jars]        = ["hbase-0.90.1-cdh3u0.jar", "hbase-0.90.1-cdh3u0-tests.jar"]
default[:pig][:hbase_configs]     = ["hbase-default.xml", "hbase-site.xml"]
default[:pig][:combine_splits]    = "false"
