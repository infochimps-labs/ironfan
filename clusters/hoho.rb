# Note that this file is retro-experimental. The original ham was set up with poolparty.

ClusterChef.cluster 'hoho' do
  use :defaults
  setup_role_implications
  cluster_role

  role "nfs_client"
  role "production"
  role "infochimps_base"
  recipe "ntp"

  cloud do 
    backing "ebs"
    image_name "infochimps-maverick-client"
  end

  facet 'hoho' do
    facet_role
    instances 1
    role "hoho"
    cloud.flavor  "m1.small"
    role "monitoring"
    server 0 do 
      chef_node_name 'hoho'
    end
  end

  facet 'boots' do
    facet_role
    instances 1
    role "boots"
    cloud.flavor  "t1.micro"
    server 0 do 
      chef_node_name = 'boots'
    end
  end

end

