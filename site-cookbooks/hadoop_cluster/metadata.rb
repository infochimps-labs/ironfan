maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs hadoop and sets up a high-performance cluster. Inspired by Tom White / Cloudera's hadoop-ec2 command line utilities"

depends          "java"
depends          "mountable_volumes"
depends          "aws"
depends          "ubuntu"
depends          "provides_service"


%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "cluster_size",
  :default               => "5",
  :display_name          => "",
  :description           => ""

attribute "hadoop/hadoop_handle",
  :default               => "hadoop-0.20",
  :display_name          => "",
  :description           => ""

attribute "hadoop/cdh_version",
  :default               => "cdh3u2",
  :display_name          => "",
  :description           => ""

attribute "hadoop/deb_version",
  :default               => "0.20.2+923.142-1~maverick-cdh3",
  :display_name          => "",
  :description           => ""

attribute "hadoop/cloudera_distro_name",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/dfs_replication",
  :default               => "3",
  :display_name          => "",
  :description           => ""

attribute "hadoop/reduce_parallel_copies",
  :default               => "10",
  :display_name          => "",
  :description           => ""

attribute "hadoop/tasktracker_http_threads",
  :default               => "32",
  :display_name          => "",
  :description           => ""

attribute "hadoop/jobtracker_handler_count",
  :default               => "40",
  :display_name          => "",
  :description           => ""

attribute "hadoop/namenode_handler_count",
  :default               => "40",
  :display_name          => "",
  :description           => ""

attribute "hadoop/datanode_handler_count",
  :default               => "8",
  :display_name          => "",
  :description           => ""

attribute "hadoop/compress_output",
  :default               => "true",
  :display_name          => "",
  :description           => ""

attribute "hadoop/compress_output_type",
  :default               => "BLOCK",
  :display_name          => "",
  :description           => ""

attribute "hadoop/compress_output_codec",
  :default               => "org.apache.hadoop.io.compress.DefaultCodec",
  :display_name          => "",
  :description           => ""

attribute "hadoop/compress_mapout",
  :default               => "true",
  :display_name          => "",
  :description           => ""

attribute "hadoop/compress_mapout_codec",
  :default               => "org.apache.hadoop.io.compress.DefaultCodec",
  :display_name          => "",
  :description           => ""

attribute "hadoop/mapred_userlog_retain_hours",
  :default               => "24",
  :display_name          => "",
  :description           => ""

attribute "hadoop/mapred_jobtracker_completeuserjobs_maximum",
  :default               => "100",
  :display_name          => "",
  :description           => ""

attribute "hadoop/extra_classpaths",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "hadoop/daemon_heapsize",
  :default               => "1000",
  :display_name          => "",
  :description           => ""

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
  :type                  => "array",
  :default               => ["/mnt/hadoop"],
  :display_name          => "",
  :description           => ""

attribute "hadoop/scratch_dirs",
  :type                  => "array",
  :default               => ["/mnt/hadoop"],
  :display_name          => "",
  :description           => ""

attribute "hadoop/max_balancer_bandwidth",
  :default               => "1048576",
  :display_name          => "",
  :description           => ""

attribute "hadoop/min_split_size",
  :default               => "134217728",
  :display_name          => "",
  :description           => ""

attribute "hadoop/s3_block_size",
  :default               => "134217728",
  :display_name          => "",
  :description           => ""

attribute "hadoop/hdfs_block_size",
  :default               => "134217728",
  :display_name          => "",
  :description           => ""

attribute "hadoop/max_map_tasks",
  :default               => "3",
  :display_name          => "",
  :description           => ""

attribute "hadoop/max_reduce_tasks",
  :default               => "2",
  :display_name          => "",
  :description           => ""

attribute "hadoop/java_child_opts",
  :default               => "-Xmx2432m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server",
  :display_name          => "",
  :description           => ""

attribute "hadoop/java_child_ulimit",
  :default               => "7471104",
  :display_name          => "",
  :description           => ""

attribute "hadoop/io_sort_factor",
  :default               => "25",
  :display_name          => "",
  :description           => ""

attribute "hadoop/io_sort_mb",
  :default               => "256",
  :display_name          => "",
  :description           => ""

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
  :type                  => "array",
  :default               => [:enable, :start],
  :display_name          => "",
  :description           => ""

attribute "service_states/hadoop_tasktracker",
  :type                  => "array",
  :default               => [:enable, :start],
  :display_name          => "",
  :description           => ""

attribute "groups/hadoop/gid",
  :default               => "300",
  :display_name          => "",
  :description           => ""

attribute "groups/supergroup/gid",
  :default               => "301",
  :display_name          => "",
  :description           => ""

attribute "groups/hdfs/gid",
  :default               => "302",
  :display_name          => "",
  :description           => ""

attribute "groups/mapred/gid",
  :default               => "303",
  :display_name          => "",
  :description           => ""

attribute "server_tuning/ulimit/hdfs",
  :type                  => "hash",
  :default               => {:nofile=>{:both=>32768}, :nproc=>{:both=>50000}},
  :display_name          => "",
  :description           => ""

attribute "server_tuning/ulimit/hbase",
  :type                  => "hash",
  :default               => {:nofile=>{:both=>32768}, :nproc=>{:both=>50000}},
  :display_name          => "",
  :description           => ""

attribute "server_tuning/ulimit/mapred",
  :type                  => "hash",
  :default               => {:nofile=>{:both=>32768}, :nproc=>{:both=>50000}},
  :display_name          => "",
  :description           => ""
