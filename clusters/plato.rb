ClusterChef.cluster 'plato' do
  use :defaults
  setup_role_implications

  role                  "infochimps_base"
  facet 'truth' do
    instances           1
 end
end
