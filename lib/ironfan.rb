require 'ironfan/requirements'

module Ironfan
  @@clusters ||= Hash.new

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
    Chef::Config[:clusters] ||= Hash.new
  end

  def self.ui=(ui) @ui = ui ; end
  def self.ui()    @ui      ; end

  def self.chef_config=(cc) @chef_config = cc ; end
  def self.chef_config()    @chef_config      ; end

  # execute against multiple targets in parallel
  def self.parallel(targets,options={})
    raise 'missing block' unless block_given?
    [targets].flatten.map do |target|
      sleep(0.1) # avoid hammering with simultaneous requests
      Thread.new(target) {|target| yield target }
    end.each(&:join) # wait for all the blocks to return
  end

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
    name = name.to_sym

    cl = ( @@clusters[name] ||= Ironfan::Dsl::Cluster.new({:name => name}) )
    cl.receive!(attrs, &block)
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
    cluster = cluster_name.to_sym
    raise ArgumentError, "Please supply a cluster name" if cluster_name.to_s.empty?
    return @@clusters[cluster] if @@clusters[cluster]

    cluster_file = cluster_filenames[cluster_name] or die("Couldn't find a definition for #{cluster_name} in cluster_path: #{cluster_path.inspect}")

    Chef::Log.info("Loading cluster #{cluster_file}")

    require cluster_file
    unless @@clusters[cluster] then  die("#{cluster_file} was supposed to have the definition for the #{cluster_name} cluster, but didn't") end

    # Flesh out the expected servers listed in the facets
    @@clusters[cluster].expand_servers!

    @@clusters[cluster]
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

  #
  # Utility to show a step of the overall process
  #
  def self.step(name, desc, *style)
    ui.info("  #{"%-15s" % (name.to_s+":")}\t#{ui.color(desc.to_s, *style)}")
  end

  #
  # Utility to do mock out a step during a dry-run
  #
  def self.unless_dry_run
    if dry_run?
      ui.info("      ... but not really")
      return nil
    else
      yield
    end
  end
  def self.dry_run?
    chef_config[:dry_run]
  end

  # Intentionally skipping an implied step 
  def self.noop(source,method,*params)
    Chef::Log.debug("Nothing to do for #{source}.#{method}(#{params.join(',')}), skipping")
  end
end
