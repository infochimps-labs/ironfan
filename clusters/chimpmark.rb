ClusterChef.cluster 'chimpmark' do
  use :defaults
  setup_role_implications
  cluster_role

  recipe                "cluster_chef::dedicated_server_tuning"
  role                  "nfs_client"
  role                  "infochimps_base"
  role                  "big_package"
  role                  "hadoop"


  recipe                "hadoop_cluster::std_hdfs_dirs"


  cloud do
    backing             "instance"
    image_name          "infochimps-maverick-client"
    region              "us-east-1"
  end

  facet 'master' do
    facet_role
    instances           1
    cloud.flavor        "m1.xlarge"
    role                "hadoop_worker"
  end

  facet 'slave' do
    facet_role
    instances           5
    cloud.flavor        "m1.xlarge"
    cloud.backing       "ebs"
    role                "hadoop_worker"
  end


  facet 'reducer' do
    facet_role do
      override_attributes({
                            :hadoop => { 
                              :max_map_tasks =>  4, 
                              :max_reduce_tasks => 2, 
                              :java_child_opts => '-Xmx1920m -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', 
                              :java_child_ulimit =>  5898240, 
                              :io_sort_factor => 25, 
                              :io_sort_mb => 256, 
                            },
                          })
    end
    
    instances 5
    cloud.flavor        "m1.xlarge"
    cloud.backing       "ebs"
    role                "hadoop_tasktracker"
    role                "hadoop_datanode"
  end

  facet 'reducest' do
    facet_role do
      override_attributes({
                            :hadoop => { 
                              :max_map_tasks =>  0, 
                              :max_reduce_tasks => 6, 
                              :java_child_opts => '-Xmx1920m -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', 
                              :java_child_ulimit =>  5898240, 
                              :io_sort_factor => 25, 
                              :io_sort_mb => 256, 
                            },
                          })
    end
    
    instances 5
    cloud.flavor        "m1.xlarge"
    cloud.backing       "ebs"
    role                "hadoop_tasktracker"
  end

  facet 'overkill' do
    facet_role do
      override_attributes({
                            :hadoop => { 
                              :max_map_tasks =>  4, 
                              :max_reduce_tasks => 2, 
                              :java_child_opts => '-Xmx1920m -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', 
                              :java_child_ulimit =>  5898240, 
                              :io_sort_factor => 25, 
                              :io_sort_mb => 256, 
                            },
                          })
    end
    
    instances 10
    cloud.flavor        "m1.xlarge"
    cloud.backing       "ebs"
    role                "hadoop_tasktracker"
  end

end
