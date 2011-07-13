ClusterChef.cluster 'sandbox' do
  recipe "sysadmin::monkeypatch_chef_gempackage"
  recipe "sysadmin::cloudera_apt_repo"
  recipe "sysadmin::opscode_apt_repo"

  use :defaults
  setup_role_implications
  mounts_ephemeral_volumes

  cluster_role do
    run_list(*%w[
       role[chef_client]
       role[infochimps_base]
       users::user_authorized_keys
    ])
  end

  cloud do
    backing "ebs"
    image_name "infochimps-maverick-client"
    flavor "t1.micro"
  end

  facet 'hohyon' do
    facet_role
    instances 1
    server 0 do
      fullname 'sandbox-hohyon'
      #cloud.flavor "m1.small"
    end
  end

  facet 'howech' do
    facet_role do
      override_attributes({
                            :chh => "Was Here!"
                          })
    end
    instances 1
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
      fullname 'sandbox-mrflip'
      volume :data, :volume_id => "vol-798fd012", :device => "/dev/sdk", :mount_point => '/data'
    end
  end

  facet 'temujin9' do
    facet_role
    instances 1
    server 0 do
      fullname 'sandbox-temujin9'
    end
    facet_role do
      run_list(*%w[
        nginx
        macaque
        macaque::server
      ])
      override_attributes({
        :macaque => {
          :forwarders => {
            :test_t9productions_com => {
              :apikey                   => 'XXXXXXXXXXXXXXXXXXX69'
            },
            :temp_t9productions_com => {}
          },
          :statsd => {
            :provider                   => 'see_no_evil',
            :name                       => 'macaque_test'
          }
        }
      })
    end
  end

  facet 'sparafina' do
    facet_role do
      override_attributes({ :extra_users => [ "sparafina" ] ,
                            :authorization => 
                            { :sudo => 
                              { :custom => 
                                [ "sparafina  ALL=(ALL) NOPASSWD:ALL" ] 
                              } 
                            }
                          })
    end
    instances 1
    server 0 do
      fullname 'sandbox-sparafina'
    end
  end
end

