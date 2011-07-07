ClusterChef.cluster 'plato' do
  use :defaults
  setup_role_implications
  cluster_role

  role                  "infochimps_base"

  cloud do
    image_name          "infochimps-maverick-client"
  end

  facet 'truth' do
    facet_role
    instances           1
 end
end
