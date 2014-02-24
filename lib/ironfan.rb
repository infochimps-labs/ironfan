require 'ironfan/requirements'

module Ironfan
  module_function

  @@clusters ||= Hash.new
  @@realms   ||= Hash.new

  # path to search for cluster definition files
  def cluster_path
    return Array(Chef::Config[:cluster_path]) if Chef::Config[:cluster_path]
    raise "Holy smokes, you have no cookbook_path or cluster_path set up. Follow chef's directions for creating a knife.rb." if Chef::Config[:cookbook_path].blank?
    cl_path = Chef::Config[:cookbook_path].map{|dir| File.expand_path('../clusters', dir) }.uniq
    ui.warn "No cluster path set. Taking a wild guess that #{cl_path.inspect} is \nreasonable based on your cookbook_path -- but please set cluster_path in your knife.rb"
    Chef::Config[:cluster_path] = cl_path
  end

  #
  # Delegates
  def clusters
    @@clusters
  end

  #
  # Delegates
  def realms
    @@realms
  end

  def ui=(ui) @ui = ui ; end
  def ui()    @ui      ; end

  def chef_config=(cc) @chef_config = cc ; end
  def chef_config()    @chef_config      ; end

  # execute against multiple targets in parallel
  def parallel(targets)
    raise 'missing block' unless block_given?
    results = []
    [targets].flatten.each_with_index.map do |target, idx|
      sleep(0.25) # avoid hammering with simultaneous requests
      Thread.new(target) do |target|
        results[idx] = safely(target.inspect) do
          yield target
        end
      end
    end.each(&:join) # wait for all the blocks to return
    results
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
  def cluster(name, attrs={}, &block)
    name = name.to_sym
    # If this is being called as Ironfan.cluster('foo') with no additional arguments,
    # return the cached cluster object if it exists
    if @@clusters[name] and attrs.empty? and not block_given?
      return @@clusters[name]
    else # Otherwise we're being asked to (re)initialize and cache a cluster definition
      cl = Ironfan::Dsl::Cluster.new(:name => name)
      cl.receive!(attrs, &block)
      @@clusters[name] = cl.resolve
    end
  end

  def realm(name, attrs={}, &block)
    name = name.to_sym
    if @@realms[name] and attrs.empty? and not block_given?
      return @@realms[name]
    else
      rlm = Ironfan::Dsl::Realm.new(:name => name)
      rlm.receive!(attrs, &block)
      rlm.clusters.keys.each{|k| @@clusters[k.to_sym] = rlm.clusters[k].resolve}
      @@realms[name] = rlm
    end
  end

  def load_realm(name)
    name = name.to_sym
    raise ArgumentError, "Please supply a realm name" if name.to_s.empty?
    return @@realms[name] if @@realms[name]

    load_cluster_files

    unless @@realms[name] then die("Couldn't find a realm definition for #{name} in #{cluster_path}") end

    @@realms[name]
  end

  #
  # Return cluster if it's defined. Otherwise, search Ironfan.cluster_path
  # for an eponymous file, load it, and return the cluster it defines.
  #
  # Raises an error if a matching file isn't found, or if loading that file
  # doesn't define the requested cluster.
  #
  # @return [Ironfan::Cluster] the requested cluster
  def load_cluster(name)
    name = name.to_sym
    raise ArgumentError, "Please supply a cluster name" if name.to_s.empty?
    return @@clusters[name] if @@clusters[name]

    load_cluster_files

    unless @@clusters[name] then die("Couldn't find a cluster definition for #{name} in #{cluster_path}") end

    @@clusters[name]
  end

  def load_cluster_files
    cluster_path.each do |cp_dir|
      Dir[ File.join(cp_dir, '*.rb') ].each do |filename|
        Chef::Log.info("Loading cluster file #{filename}")
        require filename
        clusters.values.each{|cluster| cluster.source_file ||= filename}
      end
    end
  end

  #
  # Map from cluster name to file name
  #
  # @return [Hash] map from cluster name to file name
  def cluster_filenames
    return @cluster_filenames if @cluster_filenames
    @cluster_filenames = {}
    cluster_path.each do |cp_dir|
      Dir[ File.join(cp_dir, '*.rb') ].each do |filename|
        cluster_name = File.basename(filename).gsub(/\.rb$/, '')
        @cluster_filenames[cluster_name.to_sym] ||= filename
      end
    end
    @cluster_filenames
  end

  #
  # Utility to die with an error message.
  # If the last arg is an integer, use it as the exit code.
  #
  def die *strings
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
  def safely(info="")
    begin
      yield
    rescue StandardError => err
      ui.warn("Error running #{info}:")
      ui.warn(err)
      Chef::Log.error( err )
      Chef::Log.error( err.backtrace.join("\n") )
      return err
    end
  end

  #
  # Utility to retry a flaky operation three times, with ascending wait times
  #
  # FIXME: Add specs to test the rescue here. It's a PITA to debug naturally or
  #
  # Manual test:
  # bundle exec ruby -e "require 'chef'; require 'ironfan'; Ironfan.tell_you_thrice { p 'hah'; raise 'hell' }"
  def tell_you_thrice(options={})
    options = { name:           "problem",
                error_class:    StandardError,
                retries:        3,
                multiplier:     3 }.merge!(options)
    try     = 0
    message = ''

    begin
      try += 1
      yield
    rescue options[:error_class] => err
      raise unless try < options[:retries]
      pause_for = options[:multiplier] * try
      Chef::Log.debug "Caught error (was #{err.inspect}). Sleeping #{pause_for} seconds."
      sleep pause_for
      retry
    end
  end

  #
  # Utility to show a step of the overall process
  #
  def step(name, desc, *style)
    ui.info("  #{"%-15s" % (name.to_s+":")}\t#{ui.color(desc.to_s, *style)}")
  end

  def substep(name, desc, color = :gray)
    step(name, "  - #{desc}", color) if (verbosity >= 1 or color != :gray)
  end

  def verbosity
    chef_config[:verbosity].to_i
  end

  # Output a TODO to the logs if you've switched on pestering
  def todo(*args)
    Chef::Log.debug(*args) if Chef::Config[:show_todo]
  end

  #
  # Utility to do mock out a step during a dry-run
  #
  def unless_dry_run
    if dry_run?
      ui.info("      ... but not really")
      return nil
    else
      yield
    end
  end
  def dry_run?
    chef_config[:dry_run]
  end

  # Intentionally skipping an implied step
  def noop(source,method,*params)
    # Chef::Log.debug("#{method} is a no-op for #{source} -- skipping (#{params.join(',')})")
  end
end
