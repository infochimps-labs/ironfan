ClusterChef.cluster 'howlock' do
  use :defaults
  setup_role_implications

  role                  "infochimps_base"

  cloud do
    image_name          "infochimps-maverick-client"
    flavor              'm1.xlarge'
    backing             'instance'
  end

  facet 'peer' do
    instances           3
 end
end
