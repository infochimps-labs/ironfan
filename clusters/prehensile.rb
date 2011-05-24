ClusterChef.cluster 'prehensile' do
  use :defaults
  setup_role_implications

  recipe                "hadoop_cluster::system_internals"
  role                  "attaches_ebs_volumes"
  role                  "nfs_client"
  role                  "infochimps_base"
  role                  "benchmarkable"
  cloud do
    backing             "ebs"
    image_name          "infochimps-maverick-client"
    user_data           :get_name_from => 'broham'
  end

  facet 'apeyeye' do
    instances           1
    cloud.flavor        "t1.micro"
    # Roles could go here, but we're adding the info in roles.
  end
 chef_attributes({
 })
end
