ClusterChef.cluster 'yellowhat' do
  merge!('defaults')
  setup_role_implications

  recipe                "hadoop_cluster::system_internals"
  role                  "attaches_ebs_volumes"
  role                  "nfs_client"
  role                  "infochimps_base"
  role                  "mounts_ebs_volumes"
  role                  "benchmarkable"
  cloud do
    backing             "ebs"
    image_name          "infochimps-maverick-client"
    user_data           :get_name_from => 'broham'
  end

  facet 'esnode' do
    instances           1
    cloud.flavor        "m1.small"
    role                "redis_server"
    role                "nginx"
    role                "elasticsearch_data_esnode"
    role                "elasticsearch_http_esnode"
    role                "big_package"
  end

  facet 'webnode' do
    instances           3
    cloud.flavor        "m1.small"
    role                "redis_client"
    role                "mysql_client"
    role                "elasticsearch_client"
    role                "george"
    role                "big_package"
  end

  #
  # Spof: redirects infochimps.com to www.infochimps.com
  #
  # We want to load balance web traffic to us through an AWS Elastic
  # Load Balancer but this has to be done using a CNAME so is not
  # possible at the top level of a domain. Thus we need this machine,
  # unfortunately a single point of failure (hence the name)
  #
  # Spof's purpose is to provide a static IP for a top-level A record
  # to point.  It should never run any software other than a
  # rock-solid nginx which redirects all incoming traffic to
  # www.infochimps.com -- a CNAME that points to the load balancer.
  #
  facet 'spof' do
    instances           1
    cloud.flavor         "t1.micro"
    cloud.permanent      true
    cloud.elastic_ip     "184.72.222.35"
    cloud.security_group(cluster_name+"-spof") do
      authorize_port_range  80..80
      authorize_port_range 443..443
    end
  end

  chef_attributes({
    })
end
