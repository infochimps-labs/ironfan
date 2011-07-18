ClusterChef.cluster 'demojenkins' do
  mounts_ephemeral_volumes
  setup_role_implications

  cloud do
    backing             "ebs"
    image_name          "maverick"
    flavor              "t1.micro"
    availability_zones  ['us-east-1a']
    bootstrap_distro    'ubuntu10.04-cluster_chef'
  end

  role                  :base_role
  role                  :chef_client
  role                  :ssh
  role                  :nfs_client

  jenkins_server_port = 8700
  cluster_role do
    run_list(*%w[
      role[chef_client]
    ])
    override_attributes({
        :jenkins => {
          :server => {
            :host => '0.0.0.0',
            :port => jenkins_server_port,
          }
        },
        :ruby => { :version => '1.9.1' }, # yes 1.9.1 means 1.9.2
      })
  end

  facet :master do
    instances           2
    cloud.security_group "jenkins_server" do
      authorize_port_range jenkins_server_port  # web console
    end

    facet_role do
      run_list(*%w[
       role[jenkins_server]
      ])
      #
      # role[resque]
      # role[big_package]
    end

  end

  facet :worker do
    instances           1
    cloud.security_group "jenkins_worker"

    facet_role do
      run_list(*%w[
       role[jenkins_worker]
      ])
      # role[big_package]
    end

  end

end
