ClusterChef.cluster 'chimpmark' do
  use :defaults
  setup_role_implications

  cloud do
    backing             "instance"
    image_name          "infochimps-maverick-client"
    region              "us-east-1d"
  end

  facet 'master' do
    instances           1
    cloud.flavor        "m1.xlarge"
  end

  facet 'slave' do
    instances           1
    cloud.flavor        "m1.xlarge"
  end

  chef_attributes({
  })

end
