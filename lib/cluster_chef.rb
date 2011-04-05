require 'cluster_chef/dsl_object'
require 'cluster_chef/cloud'
require 'cluster_chef/security_group'
require 'cluster_chef/compute'

module ClusterChef
  Chef::Config[:clusters] ||= {}

  def self.connection
    @connection ||= Fog::Compute.new({
        :provider              => 'AWS',
        :aws_access_key_id     => Chef::Config[:knife][:aws_access_key_id],
        :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
        #  :region                => region
      })
  end

  def self.servers
    ClusterChef.connection.servers.all
  end

  def self.running_servers
  end

  def self.clusters
    Chef::Config[:clusters]
  end


  def self.cluster name, &block
    cl = self.clusters[name] ||= ClusterChef::Cluster.new(name)
    cl.instance_eval(&block) if block
    cl
  end

  #
  # From chef, find each node by its cluster_name
  #
  def self.find_chef_by_cluster_name
    # cluster_name:*
  end

  #
  # From fog, find each node and match cluster_facets against security groups
  #


  def self.cluster_facets
    clusters.map{|cluster_name, cl| cl.facets.map{|facet_name, f| "#{cluster_name}-#{facet_name}" }}.flatten
  end
end
