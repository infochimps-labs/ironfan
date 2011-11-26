#
# Author:: Philip (flip) Kromer for Infochimps.org
# Cookbook Name:: cassandra
# Recipe:: autoconf
#
# Copyright 2010, Infochimps, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Much inspiration for this code taken from corresponding functionality in
# Benjamin Black (<b@b3k.us>)'s cassandra cookbooks
#

#
# ClusterServiceDiscovery --
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
  #
  def all_providers_for_service service_name
    all_nodes = search(:node, "provides_service:#{service_name}" ) rescue []
    all_nodes.reject!{|server| server.name == node.name}       # remove this node...
    all_nodes << node if node[:provides_service][service_name] # & use a fresh version
    all_nodes.
      find_all{|server| server[:provides_service][service_name] && server[:provides_service][service_name]['timestamp'] }.
      sort_by{|server| server[:provides_service][service_name]['timestamp'] } rescue []
  end

  # Find the most recent node that registered to provide the given service
  def provider_for_service service_name
    all_providers_for_service(service_name).last
  end

  # Find all service info for a given service name
  def all_service_info service_name
    all_providers_for_service(service_name).map do |server|
      Mash.new({
        :service    => service_name.to_sym,
        :name       => server.name,
        :cluster    => server[:cluster_name],
        :facet      => server[:facet_name],
        :index      => server[:facet_index],
        :private_ip => private_ip_of(server),
        :public_ip  => public_ip_of(server),
        :server     => server,
      }).merge(server[:provides_service][service_name])
    end
  end

  # Find the most recent associated service info for a given service name
  def service_info(service_name)
    all_service_info(service_name).last
  end

  # Register to provide the given service.
  # If you pass in a hash of information, it will be added to
  # the registry, and available to clients
  def provide_service service_name, service_info={}
    Chef::Log.info("Registering to provide #{service_name}: #{service_info.inspect}")
    node.set[:provides_service][service_name] = {
      :timestamp  => ClusterServiceDiscovery.timestamp,
    }.merge(service_info)
    node_changed!
  end

  # given service, get most recent address

  # The local-only ip address for the most recent provider for service_name
  def provider_private_ip service_name
    server = provider_for_service(service_name) or return
    private_ip_of(server)
  end

  # The local-only ip address for the most recent provider for service_name
  def provider_fqdn service_name
    server = provider_for_service(service_name) or return
    # Chef::Log.info("for #{service_name} got #{server.inspect} with #{fqdn_of(server)}")
    fqdn_of(server)
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

  # The local-only ip address for the given server
  def fqdn_of server
    server[:fqdn]
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
class Chef::Resource::Template  ; include ClusterServiceDiscovery ; end
class Erubis::Context           ; include ClusterServiceDiscovery ; end
