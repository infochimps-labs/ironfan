require 'extlib/mash'
require 'gorillib/metaprogramming/class_attribute'
require 'gorillib/hash/reverse_merge'
require 'gorillib/object/blank'
require 'gorillib/hash/compact'
require 'set'

require 'cluster_chef/dsl_object'
require 'cluster_chef/cloud'
require 'cluster_chef/security_group'
require 'cluster_chef/compute'        # base class for machine attributes
require 'cluster_chef/facet'          # similar machines within a cluster
require 'cluster_chef/cluster'        # group of machines with a common mission
require 'cluster_chef/server'         # realization of a specific facet
require 'cluster_chef/discovery'      # pair servers with Fog and Chef objects
require 'cluster_chef/server_slice'   # collection of server objects
require 'cluster_chef/volume'         # collection of server objects

Chef::Config[:clusters]          ||= Mash.new
Chef::Config[:cluster_chef_path] ||= File.expand_path(File.dirname(__FILE__)+'../..')
Chef::Config[:cluster_path]      ||= [ File.join(Chef::Config[:cluster_chef_path], "clusters") ]

module ClusterChef
  def self.cluster_path
    Chef::Config[:cluster_path]
  end

  def self.clusters
    Chef::Config[:clusters]
  end

  def self.cluster name, hsh={}, &block
    name = name.to_sym
    cl = ( self.clusters[name] ||= ClusterChef::Cluster.new(name) )
    cl.configure(hsh, &block) if block
    cl
  end

  def self.load_cluster cluster_name
    raise ArgumentError, "Please supply a cluster name" if cluster_name.to_s.empty?
    return clusters[cluster_name] if clusters[cluster_name]
    cluster_file = cluster_path.
      map{ |path| File.join( path, "#{cluster_name}.rb" ) }.
      find{|filename| File.exists?(filename) }
    unless cluster_file then die("Couldn't find a definition for #{cluster_name} in cluster_path: #{cluster_path.inspect}") ; end
    require cluster_file
    unless clusters[cluster_name] then  die("#{cluster_file} was supposed to have the definition for the #{cluster_name} cluster, but didn't") end
    clusters[cluster_name]
  end

  def self.slice cluster_name, *args
    cluster = load_cluster(cluster_name)
    cluster.resolve!
    cluster.discover!
    return cluster.slice(*args)
  end

  def self.die *strings
    exit_code = strings.last.is_a?(Integer) ? strings.pop : -1
    strings.each{|str| warn str }
    exit exit_code
  end

  def self.safely
    begin
      yield
    rescue StandardError => boom
      warn boom ; warn boom.backtrace.join("\n")
    end
  end
end

