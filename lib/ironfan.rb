require 'ironfan/requirements'
require 'pry'
module Ironfan
  module_function

  #
  # Attributes
  #
  def clusters
    Ironfan::Dsl::Cluster.definitions
  end

  def realms
    Ironfan::Dsl::Realm.definitions
  end

  def ui=(ui)           @ui = ui           ; end
  def ui()              @ui                ; end

  def chef_config=(cc)  @chef_config = cc  ; end
  def chef_config()     @chef_config       ; end

  def knife_config=(kc) @knife_config = kc ; end
  def knife_config()    @knife_config      ; end

  #
  # Dsl constructors
  #
  def cluster(name, attrs = {}, &blk)
    existing = clusters[name.to_sym]
    return existing if attrs.empty? && !block_given?
    if existing
      existing.receive!(attrs, &blk)
      existing.resolve!
    else
      cl = Ironfan::Dsl::Cluster.define(attrs.merge(name: name.to_sym), &blk)
      cl.resolve!
    end
  end

  def realm(name, attrs = {}, &blk)
    existing = realms[name.to_sym]
    return existing if attrs.empty? && !block_given?
    if existing
      existing.receive!(attrs, &blk)
      existing.resolve!
    else
      rlm = Ironfan::Dsl::Realm.define(attrs.merge(name: name.to_sym), &blk)
      rlm.resolve!
    end
  end

  #
  # Dsl loaders
  #
  def clusters_dir
    return Array(chef_config[:cluster_path]) if chef_config[:cluster_path]
    raise "Holy smokes, you have no cookbook_path or cluster_path set up. Follow chef's directions for creating a knife.rb." if chef_config[:cookbook_path].blank?
    cl_path = chef_config[:cookbook_path].map{|dir| File.expand_path('../clusters', dir) }.uniq
    ui.warn "No cluster path set. Taking a wild guess that #{cl_path.inspect} is \nreasonable based on your cookbook_path -- but please set cluster_path in your knife.rb"
    chef_config[:cluster_path] = cl_path
  end

  def realms_dir
    clusters_dir.map{ |dir| File.expand_path('../realms', dir) }.uniq
  end

  def load_cluster name
    raise ArgumentError.new('Please supply a cluster name') if name.blank?
    load_dsl_definition(name, clusters_dir)
    clusters[name.to_sym] or die("Couldn't find a cluster definition for <#{name}> in #{clusters_dir}")
  end

  def load_realm name
    raise ArgumentError.new('Please supply a realm name') if name.blank?
    load_dsl_definition(name, realms_dir)
    realms[name.to_sym] or die("Couldn't find a realm definition for <#{name}> in #{realms_dir}")
  end

  def load_dsl_definition(name, location)
    Chef::Log.info "Looking for <#{name}> dsl definition in #{location}"
    if named_file = dsl_files(location).detect{ |dsl_file| File.basename(dsl_file, '.rb') == name }
      load_dsl_file named_file
    else
      dsl_files(location).each{ |f| load_dsl_file f }
    end
  end

  def dsl_files location
    Dir.glob File.join(location, '**/*.rb')
  end

  def load_dsl_file filename
    Chef::Log.info "Loading dsl file #{filename}"
    require filename
  end

  #
  # Common utility methods
  #
  def die(*messages)
    exit_code = messages.last.is_a?(Integer) ? messages.pop : -1
    messages.each{ |msg| ui.warn msg }
    exit exit_code
  end

  def parallel(targets, &actions)
    raise ArgumentError.new('Must provide a block to run in parallel') unless block_given?
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

  def safely(operation = '', &action)
    begin
      yield
    rescue StandardError => err
      ui.warn "Error running #{operation}:"
      ui.warn err
      Chef::Log.error err
      Chef::Log.error err.backtrace.join("\n")
      return err
    end
  end

  def tell_you_thrice(options = {}, &action)
    error_class = options[:error_class] || StandardError
    retries     = options[:retries]     || 3
    multiplier  = options[:multiplier]  || 3

    attempt = 0
    begin
      attempt += 1
      yield
    rescue error_class => err
      raise if attempt > retries
      pause_for = multiplier * attempt
      Chef::Log.debug "Caught error (was #{err.inspect}). Sleeping #{pause_for} seconds."
      sleep pause_for
      retry
    end
  end

  def step(name, desc, *style)
    ui.info("  #{"%-15s" % (name.to_s+":")}\t#{ui.color(desc.to_s, *style)}")
  end

  def substep(name, desc, color = :gray)
    step(name, "  - #{desc}", color) if (verbosity >= 1 or color != :gray)
  end

  def verbosity
    knife_config[:verbosity].to_i
  end

  def todo(*args)
    Chef::Log.debug(*args) if knife_config[:show_todo]
  end

  def unless_dry_run(&action)
    if dry_run?
      ui.info("      ... but not really")
      return nil
    else
      yield
    end
  end

  def dry_run?
    knife_config[:dry_run]
  end

  def noop(source, method, *params)
    # Chef::Log.debug("#{method} is a no-op for #{source} -- skipping (#{params.join(',')})")
  end
end
