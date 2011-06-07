ClusterChef.cluster 'plato' do
  use :defaults
  setup_role_implications

  role                  "infochimps_base"

  cloud do
    image_name          "infochimps-maverick-client"
  end

  facet 'truth' do
    instances           1
 end
end
