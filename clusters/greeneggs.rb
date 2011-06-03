# Note that this file is retro-experimental. The original ham was set up with poolparty.

ClusterChef.cluster 'greeneggs' do
  use :defaults
  setup_role_implications
  
  cloud do 
    backing "instance"
    flavor  "m1.xlarge"
    image_name "infochimps-maverick-client"
    user_data :get_name_from => 'broham'
  end

  facet 'alpha' do
    instances 1
    server 0 do
      chef_node_name = 'greeneggs-alpha'
    end
    role "hbase_alpha"
  end

  facet 'beta' do
    instances 1
    chef_node_name = 'greeneggs-beta'
    role "hbase_beta"
  end
  
  facet 'gamma' do
    instances 3
    role "hbase_gamma"
  end

  facet 'delta' do
    instances 7
    role "hbase_delta"
  end
end

