ClusterChef.cluster 'microchimp' do
 use :defaults
 setup_role_implications

 cloud do
    backing "ebs"
    image_name "infochimps-maverick-client"
    #user_data  :get_name_from => 'broham'
    flavor "t1.micro"
  end

  facet 'alpha' do
    instances 1
  end

  facet 'beta' do
    instances 1
    server 0 do
      chef_node_name 'microchimp-beta'
    end
  end

  facet 'gamma' do
    instances 1
    cloud.flavor "t1.micro"
    server 0 do
      chef_node_name 'microchimp-gamma'
    end
  end

  facet 'delta' do
    instances 3
    role "microchimp_delta"
    cloud.flavor "t1.micro"
    server 1 do
      chef_node_name 'microchimp_delta_niner'
    end
  end
  chef_attributes({})
end


