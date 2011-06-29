ClusterChef.cluster 'prehensile' do
  use :defaults
  setup_role_implications

  cloud do
    backing             "ebs"
    image_name          "infochimps-maverick-client"
    user_data           :get_name_from => 'broham'
  end

  facet 'apeyeye' do
    instances           3
    cloud.flavor        "m1.small"
    server 0 do
      availability_zones  ['us-east-1d'] # default
    end
    server 1 do
      availability_zones  ['us-east-1b']
    end
    server 2 do
      availability_zones  ['us-east-1c']
    end
  end

#   # Testing stub for network-based operations
#   facet 'networkstub' do
#     instances		1
#     cloud.flavor        "m1.small"
#   end

end
