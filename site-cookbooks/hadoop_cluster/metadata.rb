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

recipe           "hadoop_cluster::cluster_conf",       "Cluster Conf"
recipe           "hadoop_cluster::datanode",           "Datanode"
recipe           "hadoop_cluster::default",            "Base configuration for hadoop_cluster"
recipe           "hadoop_cluster::doc",                "Doc"
recipe           "hadoop_cluster::ec2_conf",           "Ec2 Conf"
recipe           "hadoop_cluster::hadoop_webfront",    "Hadoop Webfront"
recipe           "hadoop_cluster::hdfs_fuse",          "Hdfs Fuse"
recipe           "hadoop_cluster::jobtracker",         "Jobtracker"
recipe           "hadoop_cluster::namenode",           "Namenode"
recipe           "hadoop_cluster::pseudo_distributed", "Pseudo Distributed"
recipe           "hadoop_cluster::secondarynamenode",  "Secondarynamenode"
recipe           "hadoop_cluster::tasktracker",        "Tasktracker"
recipe           "hadoop_cluster::wait_on_hdfs_safemode", "Wait On HDFS Safemode"
recipe           "hadoop_cluster::add_cloudera_repo",  "Add Cloudera repo to package manager"

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

attribute "hadoop/reduce_parallel_copies",
  :display_name          => "",
  :description           => "",
  :default               => "10"

attribute "hadoop/tasktracker_http_threads",
  :display_name          => "",
  :description           => "",
  :default               => "32"

attribute "hadoop/jobtracker_handler_count",
  :display_name          => "",
  :description           => "",
  :default               => "40"

attribute "hadoop/namenode_handler_count",
  :display_name          => "",
  :description           => "",
  :default               => "40"

attribute "hadoop/datanode_handler_count",
  :display_name          => "",
  :description           => "",
  :default               => "8"

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

attribute "hadoop/extra_classpaths",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => "1000"

attribute "hadoop/namenode_heapsize",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/secondarynamenode_heapsize",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/jobtracker_heapsize",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/persistent_dirs",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["/mnt/hadoop"]

attribute "hadoop/scratch_dirs",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["/mnt/hadoop"]

attribute "hadoop/max_balancer_bandwidth",
  :display_name          => "",
  :description           => "",
  :default               => "1048576"

attribute "hadoop/min_split_size",
  :display_name          => "",
  :description           => "",
  :default               => "134217728"

attribute "hadoop/s3_block_size",
  :display_name          => "",
  :description           => "",
  :default               => "134217728"

attribute "hadoop/hdfs_block_size",
  :display_name          => "",
  :description           => "",
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

attribute "hadoop/namenode/service_state",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/namenode/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/secondarynamenode/service_state",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/secondarynamenode/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/jobtracker/service_state",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/jobtracker/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/datanode/service_state",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => [:enable, :start]

attribute "hadoop/tasktracker/service_state",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => [:enable, :start]

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
