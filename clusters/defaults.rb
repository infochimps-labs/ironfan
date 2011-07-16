ClusterChef.cluster 'defaults' do
  setup_role_implications

  cloud :ec2 do
    region              'us-east-1'
    availability_zones  ['us-east-1d']
    flavor              'm1.small'
    image_name          'lucid'
    backing             'ebs'
    permanent           false
    elastic_ip          false
    spot_price_fraction nil
    security_group      :default
  end

  role                  "base_role"
  role                  "chef_client"
  role                  "ssh"
end
