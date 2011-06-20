ClusterChef.cluster 'prehensile' do
  use :defaults
  setup_role_implications

  cloud do
    backing             "ebs"
    image_name          "infochimps-maverick-client"
    user_data           :get_name_from => 'broham'
  end

  facet 'apeyeye' do
    instances           4
    cloud.flavor        "m1.small"
  end
#   
#   facet 'networkstub' do
#     instances		1
#     cloud.flavor        "m1.small"
#   end

end
