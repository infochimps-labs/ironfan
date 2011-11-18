default[:jruby][:home_dir]          = '/usr/lib/jruby'

default[:jruby][:install_url]       = "http://jruby.org.s3.amazonaws.com/downloads/1.5.6/jruby-bin-1.5.6.tar.gz"
default[:java][:java_home]         = '/usr/lib/jvm/java-6-sun/jre'

default[:jruby][:extra_jars]        = [
  "/usr/lib/hbase/hbase-0.90.1-cdh3u0.jar",
  "/usr/lib/hbase/hbase-0.90.1-cdh3u0-tests.jar",
  "/usr/lib/zookeeper/zookeeper.jar",
]

default[:jruby][:combine_splits]    = "true"
