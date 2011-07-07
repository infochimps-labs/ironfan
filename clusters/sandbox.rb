ClusterChef.cluster 'sandbox' do
  use :defaults
  setup_role_implications

  cloud do
    backing "ebs"
    image_name "infochimps-maverick-client"
    flavor "t1.micro"
  end

  facet 'hohyon' do
    instances 1
    server 0 do
      fullname 'sandbox-hohyon'
      #cloud.flavor "m1.small"
    end
  end

  facet 'howech' do
    
    instances 2
    server 0 do
      fullname 'sandbox-howech'
      volume :id => "vol-836e28e8", :device => "/dev/sdk"
    end
  end

  facet 'temujin9' do
    instances 1
    server 0 do
      fullname 'sandbox-temujin9'
    end
  end
end


