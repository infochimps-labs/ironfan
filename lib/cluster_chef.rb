require 'extlib/mash'
require 'gorillib/metaprogramming/class_attribute'
require 'gorillib/hash/reverse_merge'

require 'cluster_chef/dsl_object'
require 'cluster_chef/cloud'
require 'cluster_chef/security_group'
require 'cluster_chef/compute'        # base class for machine attributes
require 'cluster_chef/facet'          # similar machines within a cluster
require 'cluster_chef/cluster'        # group of machines with a common mission
require 'cluster_chef/server'         # realization of a specific facet

Chef::Config[:clusters]          ||= Mash.new
Chef::Config[:cluster_chef_path] ||= File.expand_path(File.dirname(__FILE__)+'../..')
Chef::Config[:cluster_path]      ||= [ File.join(Chef::Config[:cluster_chef_path], "clusters") ]

module ClusterChef
  def self.cluster_path
    Chef::Config[:cluster_path]
  end

  def self.servers
    @servers ||= ClusterChef.connection.servers.all
  end

  def self.servers_for_cluster cluster
    cluster_group = cluster.cluster_name
  end

  def self.servers_for_facet facet
    cluster_name = facet.cluster_name
    facet_name = facet.facet_name
    facet_group = "#{cluster_name}-#{facet_name}"
    servers.select {|s| s.groups.index( facet_group ) }
  end

  def self.get_cluster_slice *args
    cluster_name = args.shift
    raise ArgumentError, "Please supply a cluster name" if cluster_name.to_s.empty?

    cluster = load_cluster(cluster_name)
    return cluster.slice(*args)
  end

  def self.load_cluster cluster_name
    raise ArgumentError, "Please supply a cluster name" if cluster_name.to_s.empty?
    cluster_file = cluster_path.
      map{|path| File.join( path, "#{cluster_name}.rb" ) }.
      find{|filename| File.exists?(filename) }
    unless cluster_file then die("Couldn't find a definition for #{cluster_name} in cluster_path: #{cluster_path.inspect}") ; end
    require cluster_file
    unless clusters[cluster_name] then  die("#{cluster_file} was supposed to have the definition for the #{cluster_name} cluster, but didn't") end
    clusters[cluster_name]
  end

  def self.running_servers
  end

  def self.clusters
    Chef::Config[:clusters]
  end

  def self.cluster name, &block
    name = name.to_sym
    cl = ( self.clusters[name] ||= ClusterChef::Cluster.new(name) )
    cl.configure(&block) if block
    cl
  end

  def self.die *strings
    exit_code = strings.last.is_a?(Integer) ? strings.pop : -1
    strings.each{|str| warn str }
    exit exit_code
  end
end
