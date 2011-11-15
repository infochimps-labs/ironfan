
default[:pig][:java_home]         = '/usr/lib/jvm/java-6-sun/jre'

default[:pig][:zookeeper_jar_url] = "https://repository.apache.org/content/repositories/releases/org/apache/zookeeper/zookeeper/3.3.1/zookeeper-3.3.1.jar"
# default[:pig][:pig_hbase_patch]   = "https://issues.apache.org/jira/secure/attachment/12466652/pig-0.8.0-hbase-0.89.SNAPSHOT.patch"

# attribute "pig/zookeeper_jar_url",
#   :display_name          => "URL of zookeeper jar to add to pig",
#   :description           => "URL of zookeeper jar to download and add to pig. FIXME: integration cookbook",
#   :default               => "https://repository.apache.org/content/repositories/releases/org/apache/zookeeper/zookeeper/3.3.1/zookeeper-3.3.1.jar"
