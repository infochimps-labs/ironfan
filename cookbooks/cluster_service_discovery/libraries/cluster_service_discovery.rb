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
# * register for a service. A timestamp records the last registry.
# * discover all chef nodes that have registered for the given service.
# * discover the most recent chef node for that service.
# * get the 'public_ip' for a service -- the address that nodes in the larger
#   world should use
# * get the 'public_ip' for a service -- the address that nodes on the local
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
  def nodes_for_service service_name
    search(:node, "provides_service:#{service_name}"
      ).sort_by{|server| server[:provides_service][service_name]['timestamp'] } rescue []
  end

  # Find the most recent node that registered to provide the given service
  def node_for_service service_name
    nodes_for_service.first
  end

  # Register to provide the given service.
  # If you pass in a hash of information, it will be added to
  # the registry, and available to clients
  def register_for_service service_name, service_info={}
    node.set[:provides_service][service_name] = {
      :timestamp  => ClusterServiceDiscovery.timestamp,
    }.merge(service_info)
    node.save
  end

  # Return the private ip address for this node: the ip address a machine in the
  # local subnet / private cloud would want to reach.
  def service_private_ip service_name
    node = node_for_service(service_name) or return
    node[:cloud][:private_ips].first rescue node[:ipaddress]
  end

  # Return the public ip address for this node: the ip address a machine in the
  # larger world would want to reach.
  def service_public_ip service_name
    node = node_for_service(service_name) or return
    node[:cloud][:public_ips].first rescue node[:ipaddress]
  end

  # A compact timestamp, to record when services are registered
  def self.timestamp
    Time.now.utc.strftime("%Y%m%d%H%M%SZ")
  end

end
class Chef::Recipe              ; include ClusterServiceDiscovery ; end
class Chef::Resource::Directory ; include ClusterServiceDiscovery ; end
class Chef::Resource            ; include ClusterServiceDiscovery ; end


# a = search(:node, "provides_service:nfs_server").sort_by{|server| server[:provides_service][:nfs_server][:timestamp] } ; gm=a.first ; gm.name
# gm[:provides_service][:nfs_server]
# a = search(:node, "role:hadoop_master") ; a.first.name
# a.select{|node| node.name =~ /gibbon-master/ }.sort_by(&:name).first; gm.name
# gm[:cloud].to_hash
# a = search :node, "name:gibbon*"  ; a.length
# gm = a.reject{|n| n.run_list.grep(/hadoop_master/).blank? }.first ; gm.name

