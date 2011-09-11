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

#   facet 'howech' do
#     facet_role do
#       override_attributes({
#           :chh => "Was Here!"
#         })
#     end
#     instances 2
#     server 0 do
#       fullname 'sandbox-howech'
#       volume :data, :volume_id => "vol-836e28e8", :device => "/dev/sdk"
#     end
#     server 1 do
#       fullname 'sandbox-howech-databuilder'
#       volume :millionsong, :volume_id => "vol-c3d6e2a8", :device => "/dev/sdk", :mount_point => '/millionsong'
#       volume :millionsongunzipped, :volume_id => "vol-0580b46e", :device => "/dev/sdl", :mount_point => 'msong_unzipped'
#       cloud.flavor "m1.small"
#     end
#   end

  facet 'mrflip' do
    instances 1
    #cloud.elastic_ip '75.101.133.139'
    cloud.flavor "c1.xlarge"
    facet_role do
      run_list(*%w[
        cluster_chef::dedicated_server_tuning
        role[nfs_client]
      ])
      # rvm
      # rvm::gem_package
      # cornelius
      override_attributes({
          :rvm => {
            :default_ruby                 => "ruby-1.9.2",
            :rubies                       => [ "ruby-1.9.2" ],
            :gem_package => {
              :rvm_string                 => %w[ruby-1.9.2]
            }
          }
        })
    end
    server 0 do
      fullname 'sandbox-mrflip'
      volume :data, :volume_id => "vol-798fd012", :device => "/dev/sdk", :mount_point => '/data'
    end
  end

  facet 'dhruv' do
    instances 1
    facet_role do
      run_list(*%w[
        cluster_chef::dedicated_server_tuning
        role[nfs_client]
      ])
    end
    server 0 do
      fullname 'sandbox-dhruv'
      volume :data, :volume_id => "vol-dd1524b6", :device => "/dev/sdk", :mount_point => '/data'
    end
  end

  # NOTES:
  # - ruby-shadow gem required to edit location of ubuntu user home directory, not installed on chef-nonce
  # From https://gist.github.com/796787/0e43938bdc75b7153849efd8186cf39a8745a24c:
  # http://groups.google.com/group/rundeck-discuss/browse_thread/thread/578622f7e743675b
  # - sudo apt-get install openjdk-6-jre openjdk-6-jdk
  # - chown -R rundeck:rundeck /var/rundeck /var/log/rundeck /var/lib/rundeck
  # - visudo    ## allow sudo chef-client
  facet 'temujin9' do
    facet_role
    instances 1
    cloud.image_id          "ami-32a0535b"      # Set to the one that worked for buzzkill
    cloud.flavor "m1.small"                     # openjdk pegs CPU endlessly on a micro
    server 0 do
      fullname 'sandbox-temujin9'
    end
    facet_role do
      run_list(*%w[
      ])
      override_attributes({
          :authorization =>
          { :sudo =>
            { :custom =>
              [ "temujin9  ALL=(ALL) NOPASSWD:ALL" ]
            }
          },
        })
    end
  end

  facet 'sparafina' do
    facet_role do
      override_attributes({
          :extra_users => [ "sparafina" ] ,
          :authorization =>
          { :sudo =>
            { :custom =>
              [ "sparafina  ALL=(ALL) NOPASSWD:ALL" ]
            }
          }
        })
    end
    instances 2
    cloud.flavor        "m1.large"
    server 0 do
      cloud.image_id      "ami-f6e11d9f"
      fullname 'sandbox-sparafina'
      volume :data, :volume_id => "vol-e126128a", :device => "/dev/sdk", :mount_point => '/data'
    end

  end
end

