module FlumeCluster

  # Returns the name of the cluster that this flume is playing with
  def flume_cluster
    node[:flume][:cluster_name]
  end
  
  # returns an array containing the list of flume-masters in this cluster
  def flume_masters
    all_provider_private_ips( "#{flume_cluster}-flume-master" ).sort
  end

  # returns the index of the current host in th list of flume masters
  def flume_master_id
    flume_masters.find_index( private_ip_of( node ) )
  end
  
  # returns true if this flume is managed by an external zookeeper
  def flume_external_zookeeper
    node[:flume][:master][:external_zookeeper]
  end
  
  # returns the list of ips of zookeepers in this cluster
  def flume_zookeepers
    all_provider_private_ips(  "#{flume_cluster}-zookeeper" )
  end
  
  # returns the port to talk to zookeeper on
  def flume_zookeeper_port
    node[:flume][:master][:zookeeper_port]
end
  
  # returns the list of zookeeper servers with ports
  def flume_zookeeper_list
    flume_zookeepers.map{ |zk| "#{zk}:#{flume_zookeeper_port}"}
  end
  
  
  # returns the list of plugin classes to include
  def flume_plugin_classes
    node[:flume][:plugins].inject( node[:flume][:classes] ) do |classes,(name,plugin)| 
      classes + plugin[:classes]
    end.sort.uniq
  end
  
  # returns the list of dirs and jars to include on the FLUME_CLASSPATH
  def flume_classpath
    node[:flume][:plugins].inject( node[:flume][:classpath] ) do | cp, (name,plugin) |
      cp + plugin[:classpath]
    end.sort.uniq
  end

  def flume_java_opts
    node[:flume][:plugins].inject( node[:flume][:java_opts] ) do | cp, (name,plugin) |
      cp + plugin[:java_opts]
    end.sort.uniq
  end
  
end
 
