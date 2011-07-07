ClusterChef.cluster 'microchimp' do
 use :defaults
 setup_role_implications
 cluster_role

 cloud do
    backing "ebs"
    image_name "infochimps-maverick-client"
    #user_data  :get_name_from => 'broham'
    flavor "m1.small"
  end

  facet 'alpha' do
    facet_role
    instances 1
    server 0 do
      chef_node_name 'microchimp-alpha'
    end
  end

  facet 'beta' do
    facet_role
    instances 1
    server 0 do
      chef_node_name 'microchimp-beta'
    end
  end

  facet 'gamma' do
    facet_role
    instances 1
    server 0 do
      chef_node_name 'microchimp-gamma'
    end
  end

#  facet 'delta' do
#    instances 3
#    role "microchimp_delta"
#    cloud.flavor "t1.micro"
#    server 1 do
#      chef_node_name 'microchimp_delta_niner'
#    end
#  end
end
