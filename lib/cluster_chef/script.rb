require 'cluster_chef'

module ClusterChef
  def self.connection
    @connection ||= Fog::Compute.new({
        :provider              => 'AWS',
        :aws_access_key_id     => Chef::Config[:knife][:aws_access_key_id],
        :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
        #  :region                => region
      })
  end

  def self.fog_servers
    @fog_servers ||= ClusterChef.connection.servers.all
  end
end
