#
# ClusterServiceDiscovery --
#
# Since there's no good way to do this yet, let's at least put an abstraction in
# place.
#
# This module lets all the various moving parts register themselves for a role
#
# Currently, it maintains a databag called 'servers_info', with items named for
# each cluster_role
#
module ClusterServiceDiscovery

  # Look in the 'servers_info' databag for the 
  def address_for_role role
    host_for_role(role)['private_ip'] rescue nil
  end

  def host_for_role role
    data_bag_item('servers_info', "#{node[:cluster_name]}-#{role}")
  end

  def register_for_role cluster_role
    node.set[:provides_service][cluster_role] = {
      :timestamp => timestamp,
      :private_ip => my_private_ip, :public_ip => my_public_ip, :default_ip => my_default_ip, :fqdn => my_fqdn  }
  end

  def search_for_node node_name
    search(:node, node_name) do |server|
      node[:cloud_private_ips]
    end
  end

  def self.my_default_ip()        node[:ipaddress]                            ; end
  def self.my_fqdn()              node[:fqdn]                                 ; end
  def self.my_availability_zone() node[:ec2][:availability_zone]              ; end
  def self.timestamp()            Time.now.utc.strftime("%Y%m%d%H%M%SZ")      ; end

  # Return the private ip address for this node: the ip address a machine on the
  # local subnet would want to reach.
  def self.my_private_ip
    node[:cloud][:private_ips].first rescue default_ip
  end

  # Return the public ip address for this node: the ip address a machine in the
  # larger world would want to reach.
  def self.my_public_ip
    node[:cloud][:public_ips].first rescue default_ip
  end

  # a = search(:node, "provides_service:nfs_server").sort_by{|server| server[:provides_service][:nfs_server][:timestamp] } ; gm=a.first ; gm.name
  # gm[:provides_service][:nfs_server]
  # a = search(:node, "role:hadoop_master") ; a.first.name
  # a.select{|node| node.name =~ /gibbon-master/ }.sort_by(&:name).first; gm.name
  # gm[:cloud].to_hash
  # a = search :node, "name:gibbon*"  ; a.length
  # gm = a.reject{|n| n.run_list.grep(/hadoop_master/).blank? }.first ; gm.name
  
end

class Chef::Recipe              ; include ClusterServiceDiscovery ; end
class Chef::Resource::Directory ; include ClusterServiceDiscovery ; end
class Chef::Resource            ; include ClusterServiceDiscovery ; end

