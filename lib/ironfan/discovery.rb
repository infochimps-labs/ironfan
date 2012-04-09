module Ironfan
  class Cluster

    def discover!
      @rackspace_instance_hash = {}
      discover_ironfan!
      discover_chef_nodes!
      discover_fog_servers!  unless Ironfan.chef_config[:cloud] == false
      discover_chef_clients!
#       discover_volumes!
    end

    def chef_clients
      return @chef_clients if @chef_clients
      @chef_clients = []

      # Oh for fuck's sake -- the key used to index clients changed from
      # 'clientname' in 0.10.4-and-prev to 'name' in 0.10.8. Rather than index
      # both 'clientname' and 'name', they switched it -- so we have to fall
      # back.  FIXME: While the Opscode platform is 0.10.4 I have clientname
      # first (sorry, people of the future). When it switches to 0.10.8 we'll
      # reverse them (suck it people of the past).
      # Also sometimes the server returns results that are nil on
      # recently-expired clients, so that's annoying too.
      clients, wtf, num = Chef::Search::Query.new.search(:client, "clientname:#{cluster_name}-*") ; clients.compact!
      clients, wtf, num = Chef::Search::Query.new.search(:client, "name:#{cluster_name}-*") if clients.blank?
      clients.each do |client_hsh|
        next if client_hsh.nil?
        # Return values from Chef::Search seem to be inconsistent across chef
        # versions (sometimes a hash, sometimes an object). Fix if necessary.
        client_hsh = Chef::ApiClient.json_create(client_hsh) unless client_hsh.is_a?(Chef::ApiClient)
        @chef_clients.push( client_hsh )
      end
      @chef_clients
    end

    # returns client with the given name if in catalog, nil otherwise
    def find_client(cl_name)
      chef_clients.find{|ccl| ccl.name == cl_name }
    end

    def chef_nodes
      return @chef_nodes if @chef_nodes
      @chef_nodes = []
      Chef::Search::Query.new.search(:node,"cluster_name:#{cluster_name}") do |n|
        @chef_nodes.push(n) unless n.blank? || (n.cluster_name != cluster_name.to_s)
      end
      @chef_nodes
    end

    # returns node with the given name if in catalog, nil otherwise
    def find_node(nd_name)
      chef_nodes.find{|nd| nd.name == nd_name }
    end

  protected

    def fog_servers
#       @fog_servers ||= Ironfan.fog_servers.select{|fs| fs.key_name == cluster_name.to_s && (fs.state != "terminated") }
      @fog_servers ||= Ironfan.fog_servers.select{|fs| fs.state != "terminated" }
    end

    # Walk the list of chef nodes and
    # * vivify the server,
    # * associate the chef node
    # * if the chef node knows about its instance id, memorize that for lookup
    #   when we discover cloud instances.
    def discover_chef_nodes!
      chef_nodes.each do |chef_node|
        if chef_node["cluster_name"] && chef_node["facet_name"] && chef_node["facet_index"]
          cluster_name = chef_node["cluster_name"]
          facet_name   = chef_node["facet_name"]
          facet_index  = chef_node["facet_index"]
        elsif chef_node.name
          ( cluster_name, facet_name, facet_index ) = chef_node.name.split(/-/)
        else
          next
        end
        svr = Ironfan::Server.get(cluster_name, facet_name, facet_index)
        svr.chef_node = chef_node
        @rackspace_instance_hash[ chef_node.rackspace.instance_id ] = svr if chef_node[:rackspace] && chef_node.rackspace.respond_to?(:instance_id)
      end
    end

    # Walk the list of servers, asking each to discover its chef client.
    def discover_chef_clients!
      servers.each(&:chef_client)
    end

    # calling #servers vivifies each facet's Ironfan::Server instances
    def discover_ironfan!
      self.servers
    end

    def discover_fog_servers!
      # If the fog server is tagged with cluster/facet/index, then try to
      # locate the corresponding machine in the cluster def
      # Otherwise, try to get to it through mapping the Rackspace instance id
      # to the chef node name found in the chef node
      fog_servers.each do |fs|
        def fs.tags
          tags = {}
          tags["cluster"], tags["facet"], tags["index"] = self.name.split('-')
          tags
        end
        
        if fs.tags["cluster"] && fs.tags["facet"] && fs.tags["index"] && fs.tags["cluster"] == cluster_name.to_s
          svr = Ironfan::Server.get(fs.tags["cluster"], fs.tags["facet"], fs.tags["index"])
        elsif @rackspace_instance_hash[fs.id]
          svr = @rackspace_instance_hash[fs.id]
        else
          next
        end

        # If there already is a fog server there, then issue a warning and slap
        # the just-discovered one onto a server with an arbitrary index, and
        # mark both bogus
        if existing_fs = svr.fog_server
          if existing_fs.id != fs.id
            ui.warn "Duplicate fog instance found for #{svr.fullname}: #{fs.id} and #{existing_fs.id}!!"
            old_svr = svr
            svr     = old_svr.facet.server(1_000 + svr.facet_index.to_i)
            old_svr.bogosity :duplicate
            svr.bogosity     :duplicate
          end
        end
        svr.fog_server = fs
      end
    end

    def discover_volumes!
      servers.each(&:discover_volumes!)
    end

    def discover_addresses!
      servers.each(&:discover_addresses!)
    end

  end # Ironfan::Cluster
end

module Ironfan

  def self.fog_connection
    @fog_connection ||= Fog::Compute.new({
        :provider                       => 'Rackspace',
        :rackspace_api_key              => Chef::Config[:knife][:rackspace_api_key],
        :rackspace_username             => Chef::Config[:knife][:rackspace_username],
#         :provider                       => 'OpenStack',
#         :openstack_api_key              => Chef::Config[:knife][:rackspace_api_key],
#         :openstack_username             => Chef::Config[:knife][:rackspace_username],
#         :openstack_auth_url             => Chef::Config[:knife][:rackspace_auth_url],
#         :openstack_compute_service_name => Chef::Config[:knife][:rackspace_compute_service_name]
      })
  end

  def self.fog_servers
    return @fog_servers if @fog_servers
    Chef::Log.debug("Using fog to catalog all servers")
    @fog_servers = Ironfan.fog_connection.servers.all
  end

  def self.fog_addresses
    return @fog_addresses if @fog_addresses
    Chef::Log.debug("Using fog to catalog all addresses")
    @fog_addresses = {}.tap{|hsh| Ironfan.fog_connection.addresses.each{|fa| hsh[fa.public_ip] = fa } }
  end

  def self.fog_volumes
    @fog_volumes || fetch_fog_volumes
  end

  def self.fetch_fog_volumes
    Chef::Log.debug("Using fog to catalog all volumes - DISABLED")
#     @fog_volumes = Ironfan.fog_connection.volumes
  end

  def self.fog_keypairs
    return @fog_keypairs if @fog_keypairs
    Chef::Log.debug("Using fog to catalog all keypairs - DISABLED")
#     @fog_keypairs = {}.tap{|hsh| Ironfan.fog_connection.key_pairs.each{|kp| hsh[kp.name] = kp } }
    nil
  end

  def safely *args, &block
    Ironfan.safely(*args, &block)
  end

end
