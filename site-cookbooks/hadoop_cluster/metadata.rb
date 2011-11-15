maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs hadoop and sets up a high-performance cluster. Inspired by Tom White / Cloudera's hadoop-ec2 command line utilities"

depends          "java"
depends          "apt"
depends          "runit"
depends          "mountable_volumes"
depends          "provides_service"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "cluster_size",
  :display_name          => "",
  :description           => "",
  :default               => "5"

attribute "hadoop/hadoop_handle",
  :display_name          => "",
  :description           => "",
  :default               => "hadoop-0.20"

attribute "hadoop/cdh_version",
  :display_name          => "",
  :description           => "",
  :default               => "cdh3u2"

attribute "hadoop/deb_version",
  :display_name          => "",
  :description           => "",
  :default               => "0.20.2+923.142-1~maverick-cdh3"

attribute "hadoop/cloudera_distro_name",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/dfs_replication",
  :display_name          => "",
  :description           => "",
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
  :default               => "true"

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

attribute "hadoop/mapred_userlog_retain_hours",
  :display_name          => "",
  :description           => "",
  :default               => "24"

attribute "hadoop/mapred_jobtracker_completeuserjobs_maximum",
  :display_name          => "",
  :description           => "",
  :default               => "100"

attribute "hadoop/extra_classpaths",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/daemon_heapsize",
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
  :default               => "256"

attribute "service_states/hadoop_namenode",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "service_states/hadoop_secondarynamenode",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "service_states/hadoop_jobtracker",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "service_states/hadoop_datanode",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => [:enable, :start]

attribute "service_states/hadoop_tasktracker",
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
