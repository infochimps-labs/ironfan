Ironfan.realm 'samurai' do
  cluster 'gunbai' do
    cloud(:ec2) do
      permanent           false
      availability_zones ['us-east-1d']
      flavor              't1.micro'
      backing             'ebs'
      image_name          'natty'
      bootstrap_distro    'ubuntu10.04-ironfan'
      chef_client_script  'client.rb'
      mount_ephemerals
    end

    environment           :dev

    role                  :ssh
    cloud(:ec2).security_group(:ssh).authorize_port_range(22..22)

    facet :hub do
    end

    facet :spoke do
      environment           :other
    end
  end
end
