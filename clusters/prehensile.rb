ClusterChef.cluster 'prehensile' do
  use :defaults
  setup_role_implications
  cluster_role

  cloud do
    backing             "ebs"
    image_name          "infochimps-maverick-client"
    user_data           :get_name_from => 'broham'
  end

  facet 'apeyeye' do
    facet_role
    instances           3
    cloud.flavor        "m1.small"
    server 0 do
      cloud.availability_zones  ['us-east-1d'] # default
    end
    server 1 do
      cloud.availability_zones  ['us-east-1b']
    end
    server 2 do
      cloud.availability_zones  ['us-east-1c']
    end
  end

  facet 'staging' do
    facet_role
    instances           1
    cloud.flavor        "m1.small"
  end

  facet 'development' do
    instances           1
    cloud.flavor        "m1.small"
    facet_role do
      run_list(*%w[
        rvm
        rvm::gem_package
        mysql::client
        nginx
        unicorn
        buzzkill
        buzzkill::server
        apey_eye_endpoints
        apey_eye_endpoints::apey_eye_endpoints_no_auth
        apey_eye_endpoints::elasticsearch_proxy
        macaque
        cornelius
      ])
      override_attributes({
        :buzzkill => {
          :environment                => 'development',
          :deploy_version             => '805149744ca9498db662c85f66acde0f34c622c1',
          :forwarders => {
            :apey_eye => {
              :url                    => 'http://localhost:9500',
              :auth_mode              => 'lazy'
            },
            :passthru => {
              :url                    => 'http://localhost:9501',
            },
            :planetof => {
              :url                    => 'http://localhost:9502',
              :auth_mode              => 'lazy'
            }
          },
          :statsd => {
            :provider                 => 'see_no_evil',
            :name                     => 'buzzkill_development'
          },
          :mongo => {
            :provider                 => 'sausageparty-mongodb-server',
            :db                       => 'broham_development'
          },
        },
        :apey_eye_endpoints => {
          :environment                => 'development',
          :staging_deploy_version     => 'e45ca3f2b8f010f407213949947d5f8f00980b56',
          :deploy_version             => 'e45ca3f2b8f010f407213949947d5f8f00980b56',
          :dir                        => '/var/www/apey_eye_endpoints',
          :unicorn => {
            :num_workers              => 20,
            :listener                 => '127.0.0.1:9500'
          },
          :elasticsearch => {
            :host                     => "localhost"
          }
        },
        :macaque => {
          :deploy_version             => '4b11a97c20da310fb03afd8983537a26ae59cb11',
          :port                       => 9501,
          :forwarders => {
            :api_qwerly_com => {
              :set_params => {
                :api_key              => 'a5kb2eh3j9j7xcr8c3kzqx36'
              },
            },
            :money_bundle_com         => {},
            :svc_webservius_com  => {
              :set_params => {
                :wsvKey               => '2xoR2WrD1DoxZDO4nsJascOFhH2SJhto'
              },
            },
          },
          :statsd => {
            :provider                 => 'see_no_evil',
            :name                     => 'passthru'
          }
        },
        :cornelius => {
          :port                       => 9502,
          :elastic_search => {
            :port                     => 9200,
            :host                     => "10.112.238.81",
          }
        },
        :rvm => {
          :group_id                   => 427,
          :default_ruby               => "system",
          :rubies                     => [ "ruby-1.9.2" ],
          :gem_package => {
            :rvm_string               => %w[system ruby-1.9.2]
          }
        },
        :statsd => {
          :flushInterval              => 60000
        }
      })
    end
  end

#   # Testing stub for network-based operations
#   facet 'networkstub' do
#     instances         1
#     cloud.flavor        "m1.small"
#   end

#   facet 'passthru' do
#     facet_role
# #     instances           3
#     instances           1
#     cloud.flavor        "m1.small"
#     server 0 do
#       cloud.availability_zones  ['us-east-1d'] # default
#     end
#     server 1 do
#       cloud.availability_zones  ['us-east-1b']
#     end
#     server 2 do
#       cloud.availability_zones  ['us-east-1c']
#     end
#   end

end
