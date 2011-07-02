name        'monkeyballs_cluster'
description 'Holds cluster-wider overrides and recipes for the monkeyballs cluster'

# Force these attributes overriding all else
override_attributes({
    :extra_users => [ "allie" ] ,
    :cluster_size => 3,

    :hadoop => {
      :max_map_tasks    => 16,
      :max_reduce_tasks => 2,
      :cdh_version =>  "cdh3",

      :hadoop_daemon_heapsize            => 1000,
      :hadoop_namenode_heapsize          => 4000,
      :hadoop_secondarynamenode_heapsize => 4000,
      :hadoop_jobtracker_heapsize        => 4000,

    },
  })
