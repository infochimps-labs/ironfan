module FlumeCluster

  # Returns the name of the cluster that this flume is playing with
  def flume_cluster
    node[:flume][:cluster_name]
  end

  # returns an array containing the list of flume-masters in this cluster
  def flume_masters
    discover_all(:flume, :master).map(&:private_ip).sort
  end

  def flume_master
    flume_masters.first
  end

  # returns the index of the current host in th list of flume masters
  def flume_master_id
    flume_masters.find_index( ClusterChef::NodeUtils.private_ip_of( node ) )
  end

  # returns true if this flume is managed by an external zookeeper
  def flume_external_zookeeper
    node[:flume][:master][:external_zookeeper]
  end

  # returns the list of ips of zookeepers in this cluster
  def flume_zookeepers
    discover_all(:zookeeper, :server).map(&:private_ip).sort
  end

  # returns the port to talk to zookeeper on
  def flume_zookeeper_port
    node[:flume][:master][:zookeeper_port]
end

  # returns the list of zookeeper servers with ports
  def flume_zookeeper_list
    flume_zookeepers.map{ |zk| "#{zk}:#{flume_zookeeper_port}"}
  end


  def flume_collect_property( property )
    initial = node[:flume][property]
    initial = [] unless initial
    node[:flume][:plugins].inject( initial ) do | collection, (name,plugin) |
      collection += plugin[property] if plugin[property]
      collection
    end
  end

  # returns the list of plugin classes to include
  def flume_plugin_classes
    flume_collect_property( :classes )
  end

  # returns the list of dirs and jars to include on the FLUME_CLASSPATH
  def flume_classpath
    flume_collect_property( :classpath )
  end

  def flume_java_opts
    flume_collect_property( :java_opts )
  end

end
