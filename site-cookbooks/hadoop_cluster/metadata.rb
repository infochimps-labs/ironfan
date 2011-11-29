maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.1"

description      "Installs hadoop and sets up a high-performance cluster. Inspired by Tom White / Cloudera's hadoop-ec2 command line utilities."

depends          "java"
depends          "apt"
depends          "runit"
depends          "mountable_volumes"
depends          "provides_service"
depends          "cluster_chef"

recipe           "hadoop_cluster::default",            "Base configuration for hadoop_cluster"
recipe           "hadoop_cluster::add_cloudera_repo",  "Add Cloudera repo to package manager"
recipe           "hadoop_cluster::cluster_conf",       "Configure cluster"

recipe           "hadoop_cluster::datanode",           "Installs Hadoop Datanode service"
recipe           "hadoop_cluster::secondarynn",        "Installs Hadoop Secondary Namenode service"
recipe           "hadoop_cluster::tasktracker",        "Installs Hadoop Tasktracker service"
recipe           "hadoop_cluster::jobtracker",         "Installs Hadoop Jobtracker service"
recipe           "hadoop_cluster::namenode",           "Installs Hadoop Namenode service"
recipe           "hadoop_cluster::doc",                "Installs Hadoop documentation"
recipe           "hadoop_cluster::hdfs_fuse",          "Installs Hadoop HDFS Fuse service (regular filesystem access to HDFS files)"

recipe           "hadoop_cluster::wait_on_hdfs_safemode", "Wait on HDFS Safemode -- insert between cookbooks to ensure HDFS is available"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "cluster_size",
  :display_name          => "Number of machines in the cluster",
  :description           => "Number of machines in the cluster. This is used to size things like handler counts, etc.",
  :default               => "5"

attribute "apt/cloudera/force_distro",
  :display_name          => "Override the distro name apt uses to look up repos",
  :description           => "Typically, leave this blank. However if (as is the case in Nov 2011) you are on natty but Cloudera's repo only has packages up to maverick, use this to override.",
  :default               => ""

attribute "apt/cloudera/release_name",
  :display_name          => "Release identifier (eg cdh3u2) of the cloudera repo to use. See also hadoop/deb_version",
  :description           => "Release identifier (eg cdh3u2) of the cloudera repo to use. See also hadoop/deb_version",
  :default               => "cdh3u2"

attribute "hadoop/handle",
  :display_name          => "Version prefix for the daemons and other components",
  :description           => "Cloudera distros have a prefix most (but not all) things with. This helps isolate the times they say 'hadoop-0.20' vs. 'hadoop'",
  :default               => "hadoop-0.20"

attribute "hadoop/deb_version",
  :display_name          => "Apt revision identifier (eg 0.20.2+923.142-1~maverick-cdh3) of the specific cloudera apt to use. See also apt/release_name",
  :description           => "Apt revision identifier (eg 0.20.2+923.142-1~maverick-cdh3) of the specific cloudera apt to use. See also apt/release_name",
  :default               => "0.20.2+923.142-1~maverick-cdh3"



attribute "hadoop/dfs_replication",
  :display_name          => "Default HDFS replication factor",
  :description           => "HDFS blocks are by default reproduced to this many machines.",
  :default               => "3"


attribute "hadoop/jobtracker/handler_count",
  :display_name          => "",
  :description           => "",
  :default               => "40"

attribute "hadoop/namenode/handler_count",
  :display_name          => "",
  :description           => "",
  :default               => "40"

attribute "hadoop/datanode/handler_count",
  :display_name          => "",
  :description           => "",
  :default               => "8"

attribute "hadoop/reducer_parallel_copies",
  :display_name          => "",
  :description           => "",
  :default               => "10"

attribute "hadoop/tasktracker/http_threads",
  :display_name          => "",
  :description           => "",
  :default               => "32"

attribute "hadoop/compress_output",
  :display_name          => "",
  :description           => "",
  :default               => "false"

attribute "hadoop/compress_output_type",
  :display_name          => "",
  :description           => "",
  :default               => "BLOCK"

attribute "hadoop/compress_output_codec",
  :display_name          => "",
  :description           => "",
  :default               => "org.apache.hadoop.io.compress.DefaultCodec"

attribute "hadoop/compress_mapout",
  :display_name          => "",
  :description           => "",
  :default               => "true"

attribute "hadoop/compress_mapout_codec",
  :display_name          => "",
  :description           => "",
  :default               => "org.apache.hadoop.io.compress.DefaultCodec"

attribute "hadoop/log_retention_hours",
  :display_name          => "",
  :description           => "See [Hadoop Log Location and Retention](http://www.cloudera.com/blog/2010/11/hadoop-log-location-and-retention) for more.",
  :default               => "24"

attribute "hadoop/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => "1000"

attribute "hadoop/max_balancer_bandwidth",
  :display_name          => "",
  :description           => "",
  :default               => "1048576"

attribute "hadoop/min_split_size",
  :display_name          => "",
  :description           => "",
  :default               => "134217728"

attribute "hadoop/s3_block_size",
  :display_name          => "fs.s3n.block.size",
  :description           => "Block size to use when reading files using the native S3 filesystem (s3n: URIs).",
  :default               => "134217728"

attribute "hadoop/hdfs_block_size",
  :display_name          => "dfs.block.size",
  :description           => "The default block size for new files",
  :default               => "134217728"

attribute "hadoop/max_map_tasks",
  :display_name          => "",
  :description           => "",
  :default               => "3"

attribute "hadoop/max_reduce_tasks",
  :display_name          => "",
  :description           => "",
  :default               => "2"

attribute "hadoop/java_child_opts",
  :display_name          => "",
  :description           => "",
  :default               => "-Xmx2432m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server"

attribute "hadoop/java_child_ulimit",
  :display_name          => "",
  :description           => "",
  :default               => "7471104"

attribute "hadoop/io_sort_factor",
  :display_name          => "",
  :description           => "",
  :default               => "25"

attribute "hadoop/io_sort_mb",
  :display_name          => "",
  :description           => "",
  :default               => "250"

attribute "hadoop/extra_classpaths",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/namenode/run_state",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/secondarynn/run_state",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/jobtracker/run_state",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/datanode/run_state",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => [:enable, :start]

attribute "hadoop/tasktracker/run_state",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => [:enable, :start]

attribute "hadoop/namenode/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/secondarynn/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/jobtracker/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/datanode/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/tasktracker/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "groups/hadoop/gid",
  :display_name          => "",
  :description           => "",
  :default               => "300"

attribute "groups/supergroup/gid",
  :display_name          => "",
  :description           => "",
  :default               => "301"

attribute "groups/hdfs/gid",
  :display_name          => "",
  :description           => "",
  :default               => "302"

attribute "groups/mapred/gid",
  :display_name          => "",
  :description           => "",
  :default               => "303"

attribute "server_tuning/ulimit/hdfs",
  :display_name          => "",
  :description           => "",
  :type                  => "hash",
  :default               => {:nofile=>{:both=>32768}, :nproc=>{:both=>50000}}

attribute "server_tuning/ulimit/hbase",
  :display_name          => "",
  :description           => "",
  :type                  => "hash",
  :default               => {:nofile=>{:both=>32768}, :nproc=>{:both=>50000}}

attribute "server_tuning/ulimit/mapred",
  :display_name          => "",
  :description           => "",
  :type                  => "hash",
  :default               => {:nofile=>{:both=>32768}, :nproc=>{:both=>50000}}
