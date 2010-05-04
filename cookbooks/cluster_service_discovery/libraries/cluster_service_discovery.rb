#
# ClusterServiceDiscovery --
#
# Since there's no good way to do this yet, let's at least put an abstraction in
# place.
#
# Allow nodes to discover the location for a given service at runtime, adapting
# when new services register.
#
# Operations:
#
# * provide a service. A timestamp records the last registry.
# * discover all providers for the given service.
# * discover the most recent provider for that service.
# * get the 'public_ip' for a provider -- the address that nodes in the larger
#   world should use
# * get the 'public_ip' for a provider -- the address that nodes on the local
#   subnet / private cloud should use
#
# Implementation
#
# Nodes register a service by setting the +[:provides_service][service_name]+
# attribute. This attribute is a hash containing at 'timestamp' (the time of
# registry), but the service can pass in an arbitrary hash of values to merge
# in.
#
module ClusterServiceDiscovery

  # Find all nodes that have indicated they provide the given service,
  # in descending order of when they registered.
  def all_providers_for_service service_name
    search(:node, "provides_service:#{service_name}"
      ).sort_by{|server| server[:provides_service][service_name]['timestamp'] } rescue []
  end

  # Find the most recent node that registered to provide the given service
  def provider_for_service service_name
    all_providers_for_service(service_name).last
  end

  # Register to provide the given service.
  # If you pass in a hash of information, it will be added to
  # the registry, and available to clients
  def provide_service service_name, service_info={}
    node.set[:provides_service][service_name] = {
      :timestamp  => ClusterServiceDiscovery.timestamp,
    }.merge(service_info)
    node.save
  end

  # given service, get most recent address

  # The local-only ip address for the most recent provider for service_name
  def provider_private_ip service_name
    server = provider_for_service(service_name) or return
    private_ip_of(server)
  end

  # The globally-accessable ip address for the most recent provider for service_name
  def provider_public_ip service_name
    server = provider_for_service(service_name) or return
    public_ip_of(server)
  end

  # given service, get many addresses

  # The local-only ip address for all providers for service_name
  def all_provider_private_ips service_name
    servers = all_providers_for_service(service_name)
    servers.map{ |server| private_ip_of(server) }
  end

  # The globally-accessable ip address for all providers for service_name
  def all_provider_public_ips service_name
    servers = all_providers_for_service(service_name)
    servers.map{ |server| public_ip_of(server) }
  end

  # given server, get address

  # The local-only ip address for the given server
  def private_ip_of server
    server[:cloud][:private_ips].first rescue server[:ipaddress]
  end

  # The globally-accessable ip address for the given server
  def public_ip_of server
    server[:cloud][:public_ips].first  rescue server[:ipaddress]
  end

  # A compact timestamp, to record when services are registered
  def self.timestamp
    Time.now.utc.strftime("%Y%m%d%H%M%SZ")
  end

end
class Chef::Recipe              ; include ClusterServiceDiscovery ; end
class Chef::Resource::Directory ; include ClusterServiceDiscovery ; end
class Chef::Resource            ; include ClusterServiceDiscovery ; end


