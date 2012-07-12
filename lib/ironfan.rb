require 'chef/mash'
require 'chef/config'
#
require 'gorillib/metaprogramming/class_attribute'
require 'gorillib/hash/reverse_merge'
require 'gorillib/object/blank'
require 'gorillib/hash/compact'
require 'gorillib/builder'
require 'set'

require 'ironfan/dsl_builder'

require 'ironfan/dsl'
require 'ironfan/provider'
require 'ironfan/broker'

require 'ironfan/security_group'
require 'ironfan/cloud'
require 'ironfan/compute'           # base class for machine attributes
require 'ironfan/facet'             # similar machines within a cluster
require 'ironfan/cluster'           # group of machines with a common mission
require 'ironfan/server'            # realization of a specific facet
require 'ironfan/discovery'         # pair servers with Fog and Chef objects
require 'ironfan/server_slice'      # collection of server objects
require 'ironfan/volume'            # configure external and internal volumes
require 'ironfan/private_key'       # coordinate chef keys, cloud keypairs, etc
require 'ironfan/role_implications' # make roles trigger other actions (security groups, etc)
#
require 'ironfan/chef_layer'        # interface to chef for server actions
require 'ironfan/fog_layer'         # interface to fog  for server actions
#
require 'ironfan/deprecated'        # stuff slated to go away

module Ironfan
  @@clusters ||= Mash.new

  # path to search for cluster definition files
  def self.cluster_path
    return Array(Chef::Config[:cluster_path]) if Chef::Config[:cluster_path]
    raise "Holy smokes, you have no cookbook_path or cluster_path set up. Follow chef's directions for creating a knife.rb." if Chef::Config[:cookbook_path].blank?
    cl_path = Chef::Config[:cookbook_path].map{|dir| File.expand_path('../clusters', dir) }.uniq
    ui.warn "No cluster path set. Taking a wild guess that #{cl_path.inspect} is \nreasonable based on your cookbook_path -- but please set cluster_path in your knife.rb"
    Chef::Config[:cluster_path] = cl_path
  end

  #
  # Delegates
  def self.clusters
    Chef::Config[:clusters] ||= Mash.new
  end

  def self.ui=(ui) @ui = ui ; end
  def self.ui()    @ui      ; end

  def self.chef_config=(cc) @chef_config = cc ; end
  def self.chef_config()    @chef_config      ; end

  #
  # Defines a cluster with the given name.
  #
  # @example
  #   Ironfan.cluster 'demosimple' do
  #     cloud :ec2 do
  #       availability_zones  ['us-east-1d']
  #       flavor              "t1.micro"
  #       image_name          "ubuntu-natty"
  #     end
  #     role                  :base_role
  #     role                  :chef_client
  #
  #     facet :sandbox do
  #       instances 2
  #       role                :nfs_client
  #     end
  #   end
  #
  #
  def self.cluster(name, attrs={}, &block)
    require 'gorillib/model/serialization'
    require 'gorillib/serialization/to_wire'

    name = name.to_sym

    # Test the inactive DSL construction, compared to the active
    i = ( @@clusters[name] ||= Ironfan::Dsl::Cluster.new({:name => name}) )
    i.receive!(attrs, &block)

    cl = ( self.clusters[name] ||= Ironfan::Cluster.new(name) )
    cl.receive!(attrs, &block)
    cl
  end

  #
  # Return cluster if it's defined. Otherwise, search Ironfan.cluster_path
  # for an eponymous file, load it, and return the cluster it defines.
  #
  # Raises an error if a matching file isn't found, or if loading that file
  # doesn't define the requested cluster.
  #
  # @return [Ironfan::Cluster] the requested cluster
  def self.load_cluster(cluster_name)
    raise ArgumentError, "Please supply a cluster name" if cluster_name.to_s.empty?
    return clusters[cluster_name] if clusters[cluster_name]

    cluster_file = cluster_filenames[cluster_name] or die("Couldn't find a definition for #{cluster_name} in cluster_path: #{cluster_path.inspect}")

    Chef::Log.info("Loading cluster #{cluster_file}")

    require cluster_file
    unless clusters[cluster_name] then  die("#{cluster_file} was supposed to have the definition for the #{cluster_name} cluster, but didn't") end

    clusters[cluster_name]
  end

  #
  # Map from cluster name to file name
  #
  # @return [Hash] map from cluster name to file name
  def self.cluster_filenames
    return @cluster_filenames if @cluster_filenames
    @cluster_filenames = {}
    cluster_path.each do |cp_dir|
      Dir[ File.join(cp_dir, '*.rb') ].each do |filename|
        cluster_name = File.basename(filename).gsub(/\.rb$/, '')
        @cluster_filenames[cluster_name] ||= filename
      end
    end
    @cluster_filenames
  end

  #
  # Utility to die with an error message.
  # If the last arg is an integer, use it as the exit code.
  #
  def self.die *strings
    exit_code = strings.last.is_a?(Integer) ? strings.pop : -1
    strings.each{|str| ui.warn str }
    exit exit_code
  end

  #
  # Utility to turn an error into a warning
  #
  # @example
  #   Ironfan.safely do
  #     Ironfan.fog_connection.associate_address(self.fog_server.id, address)
  #   end
  #
  def self.safely
    begin
      yield
    rescue StandardError => boom
      ui.info( boom )
      Chef::Log.error( boom )
      Chef::Log.error( boom.backtrace.join("\n") )
    end
  end
end
