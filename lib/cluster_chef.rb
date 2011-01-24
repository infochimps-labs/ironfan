require 'cluster_chef/dsl_object'
require 'cluster_chef/cloud'
require 'cluster_chef/security_group'
require 'cluster_chef/compute'

module ClusterChef

  
  def self.connection
    @connection ||= Fog::AWS::Compute.new({
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


  def self.cluster name, &block
    Chef::Config[:clusters]       ||= {}
    cl = Chef::Config[:clusters][name] = ClusterChef::Cluster.new(name)
    cl.instance_eval(&block)
    cl
  end
  
end
