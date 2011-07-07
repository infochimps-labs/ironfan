ClusterChef.cluster 'sandbox' do
  use :defaults
  setup_role_implications
  mounts_ephemeral_volumes

  cloud do
    backing "ebs"
    image_name "infochimps-maverick-client"
    flavor "t1.micro"
  end

  facet 'hohyon' do
    instances 1
    server 0 do
      fullname 'sandbox-hohyon'
      #cloud.flavor "m1.small"
    end
  end

  facet 'howech' do
    instances 2
    server 0 do
      fullname 'sandbox-howech'
      volume :data, :volume_id => "vol-836e28e8", :device => "/dev/sdk"
    end
  end

  facet 'mrflip' do
    instances 1
    facet_role do
      run_list(*%w[
        cluster_chef::dedicated_server_tuning
        role[nfs_client]
      ])
    end
    server 0 do
      volume :data, :volume_id => "vol-798fd012", :device => "/dev/sdk", :mount_point => '/data'
    end
  end

  facet 'temujin9' do
    instances 1
    server 0 do
      fullname 'sandbox-temujin9'
    end
  end
end


