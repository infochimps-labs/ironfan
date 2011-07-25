ClusterChef.cluster 'wherelock' do
  use :defaults
  setup_role_implications
  cluster_role do
      run_list(*%w[
        role[infochimps_base]
      ])
      override_attributes({
      })
  end

  cloud do
    image_name          "infochimps-maverick-client"
    flavor              'm1.xlarge'
    backing             'instance'
  end

  facet 'peer' do
    facet_role
    instances           1
    facet_role do
      run_list(*%w[
        role[elasticsearch_peer]
        role[nfs_client]
     ])
      override_attributes({
        :elasticsearch => {
          :cluster_name        => 'wherelock',
          :default_shards      => 16,
          :default_replicas    => 0,
          :merge_factor        => 4,

          :term_index_interval => 1024,
          :ulimit_mlock        => 'unlimited', # set to "unlimited" when indexing, but leave fluid otherwise

          :index_buffer_size   => "512m",
          :heap_size           => '10000',
          :fd_ping_interval    => '2s',
          :fd_ping_timeout     => '60s',
          :fd_ping_retries     => '6',
          :recovery_after_time  => '10m',
          :recovery_after_nodes => 0,
          :expected_nodes       => 1,
          :refresh_interval     => 900,
          :snapshot_interval    => '10m',
          :snapshot_on_close    => true,

          :local_disks          => [ ['/mnt','/dev/md0'] ],

          :version              => '0.16.0',

          :s3_gateway_bucket    => 'infochimps-search-staging',
        }
      })
    end
  end
end
