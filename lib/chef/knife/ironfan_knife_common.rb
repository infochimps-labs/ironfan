module Ironfan
  module KnifeCommon
    attr_accessor :broker

    def self.load_deps
      require 'formatador'
      require 'chef/node'
      require 'chef/api_client'
      require 'fog'
      require 'rbvmomi'
    end

    def load_ironfan
      $LOAD_PATH << File.join(Chef::Config[:ironfan_path], '/lib') if Chef::Config[:ironfan_path]
      require 'ironfan'
      $stdout.sync = true
      Ironfan.ui           = self.ui
      self.config[:cloud]  = Chef::Config[:cloud] if Chef::Config.has_key?(:cloud)
      Ironfan.knife_config = self.config
      Ironfan.chef_config  = Chef::Config
      self.broker          = Ironfan.broker
    end

    def run()
      gemfile_v = gemfile(@name_args.first.to_s.split(/[_-]/).first)

      if ENV['BUNDLE_GEMFILE'] == gemfile_v
        _run
      elsif not File.exist?(gemfile_v)
        ui.info("no realm-specific Gemfile found. using default Gemfile.")
        _run
      else
        cmd = "bundle exec knife #{ARGV.join(' ')}"
        ui.info("re-running `#{cmd}` with BUNDLE_GEMFILE=#{gemfile_v}")
        return Bundler.clean_exec({'BUNDLE_GEMFILE' => gemfile_v}, cmd)
      end
    end

    def gemfile(realm_or_cluster_name)
      "Gemfile.#{realm_or_cluster_name}"
    end


    #
    # Common code for calling broker.discover with an appropriately
    # trimmed list of clusters to discover.
    #
    def discover_computers(realm_name, cluster_name, facet_name, slice_indexes)
      realm = Ironfan.load_realm(realm_name)
      realm.clusters.each{ |cluster| Ironfan.load_cluster cluster.name }
      realm.resolve!
      clusters = cluster_name ? Array(realm.clusters[cluster_name.to_sym]) : realm.clusters.to_a
      return broker.discover!(clusters, config[:cloud])
    end

    #
    # A slice of a cluster:
    #
    #
    # @return [Ironfan::ServerSlice] the requested slice
    def get_slice(slice_string, *args)
      realm_name, cluster_name, facet_name, slice_indexes = pick_apart(slice_string, *args)
      desc = predicate_str(realm_name, cluster_name, facet_name, slice_indexes)
      ui.info("Inventorying servers in #{desc}")
      computers = discover_computers(realm_name, cluster_name, facet_name, slice_indexes)
      
      Chef::Log.info("Inventoried #{computers.size} computers")      
      return computers.slice(cluster_name, facet_name, slice_indexes)
    end

    def all_computers(slice_string, *args)
      realm_name, cluster_name, facet_name, slice_indexes = pick_apart(slice_string, *args)
      computers = discover_computers(realm_name, cluster_name, facet_name, slice_indexes)
      ui.info("Loaded information for #{computers.size} computer(s) in cluster #{cluster_name}")
      computers
    end

    def pick_apart(slice_string, *args)
      if not args.empty?
        slice_string = [slice_string, args].flatten.join("-")
        ui.info("")
        ui.warn("Please specify server slices joined by dashes and not separate args:\n\n  knife cluster #{sub_command} #{slice_string}\n\n")
      end
      slice_string.split(/[\s\-]/, 4)
    end

    def predicate_str(realm_name, cluster_name, facet_name, slice_indexes)
      [ "#{ui.color(realm_name, :bold)} realm",
        (cluster_name  ? "#{ui.color(cluster_name, :bold)} cluster"  : "#{ui.color("all", :bold)} clusters"),
        (facet_name    ? "#{ui.color(facet_name, :bold)} facet"      : "#{ui.color("all", :bold)} facets"),
        (slice_indexes ? "servers #{ui.color(slice_indexes, :bold)}" : "#{ui.color("all", :bold)} servers")
      ].join(', ')
    end

    # method to nodes should be filtered on
    def relevant?(computer)
      computer.running?
    end

    # override in subclass to confirm risky actions
    def confirm_execution(*args)
      # pass
    end

    #
    # Get a slice of nodes matching the given filter
    #
    # @example
    #    target = get_relevant_slice(* @name_args)
    #
    def get_relevant_slice( *predicate )
      full_target = get_slice( *predicate )
      display(full_target) do |mach|
        rel = relevant?(mach)
        { :relevant? => (rel ? "[green]#{rel}[reset]" : '-' ) }
      end
      full_target.select{|mach| relevant?(mach) }
    end

    # passes target to Broker::Conductor#display, will show headings in server slice
    # tables based on the --verbose flag
    def display(target, display_style=nil, &block)
      display_style ||= (config[:verbosity] == 0 ? :default : :expanded)
      broker.display(target, display_style, &block)
    end

    #
    # Put Fog into mock mode if --dry_run
    #
    def configure_dry_run
      if config[:dry_run]
        Fog.mock!
        Fog::Mock.delay = 0
      end
    end

    # Show a pretty progress bar while we wait for a set of threads to finish.
    def progressbar_for_threads(threads)
      section "Waiting for servers:"
      total      = threads.length
      remaining  = threads.select(&:alive?)
      start_time = Time.now
      until remaining.empty?
        remaining = remaining.select(&:alive?)
        if config[:verbose]
          ui.info "waiting: #{total - remaining.length} / #{total}, #{(Time.now - start_time).to_i}s"
          sleep 5
        else
          Formatador.redisplay_progressbar(total - remaining.length, total, {:started_at => start_time })
          sleep 1
        end
      end
      # Collapse the threads
      threads.each(&:join)
      ui.info ''
    end

    def bootstrapper(computer)
      server   = computer.server
      hostname = computer.dns_name
      #
      bootstrap = Chef::Knife::Bootstrap.new
      bootstrap.config.merge!(config)
      #
      bootstrap.name_args               = [ hostname ]
      bootstrap.config[:computer]       = computer
      bootstrap.config[:server]         = server
      bootstrap.config[:run_list]       = server.run_list
      bootstrap.config[:ssh_user]       = config[:ssh_user]       || computer.ssh_user
      bootstrap.config[:attribute]      = config[:attribute]
      bootstrap.config[:identity_file]  = config[:identity_file]  || computer.ssh_identity_file
      bootstrap.config[:distro]         = config[:distro]         || computer.bootstrap_distro
      bootstrap.config[:use_sudo]       = true unless config[:use_sudo] == false
      bootstrap.config[:chef_node_name] = server.full_name
      bootstrap.config[:client_key]     = ( computer.client.private_key rescue nil )
      #
      bootstrap
    end

    def run_bootstrap(computer)
      bs = bootstrapper(computer)
      if config[:skip].to_s == 'true'
        ui.info "Skipping: bootstrap #{computer.name} with #{JSON.pretty_generate(bs.config)}"
        return
      end
      #
      Ironfan.step(computer.name, "Running bootstrap")
      Chef::Log.info("Bootstrapping:\n  Computer #{computer}\n  Bootstrap config #{bs.config}")
      Ironfan.safely([computer, bs.config].inspect) do
        bs.run
      end
    end

    def wait_for_ssh(computer)
      ssh = Chef::Knife::Ssh.new
      ssh.ui = ui
      ssh.name_args = [ computer.name, "ls" ]
      ssh.config[:ssh_user] = Chef::Config[:knife][:ssh_user] || config[:ssh_user]
      ssh.config[:ssh_password] = config[:ssh_password]
      ssh.config[:ssh_port] = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
      ssh.config[:ssh_gateway] = Chef::Config[:knife][:ssh_gateway] || config[:ssh_gateway]
      ssh.config[:forward_agent] = Chef::Config[:knife][:forward_agent] || config[:forward_agent]
      ssh.config[:identity_file] = Chef::Config[:knife][:identity_file] || config[:identity_file]
      ssh.config[:manual] = true
      ssh.config[:host_key_verify] = Chef::Config[:knife][:host_key_verify] || config[:host_key_verify]
      ssh.config[:on_error] = :raise
      session = ssh.session
      return true
    rescue Errno::ETIMEDOUT
      Chef::Log.debug("ssh to #{computer.name} timed out")
      return false
    rescue Errno::ECONNREFUSED
      Chef::Log.debug("ssh connection to #{computer.name} refused")
      yield
      return false
    rescue Errno::EHOSTUNREACH
      Chef::Log.debug("ssh host #{computer.name} unreachable")
      yield
      return false
    rescue 
      Chef::Log.debug("something else went wrong while wating for ssh host #{computer.name}")
      raise
      return false
    else
      session && session.close
      session = nil
    end
      
    #
    # Utilities
    #
    def sub_command
      self.class.sub_command
    end

    def confirm_or_exit question, correct_answer
      response = ui.ask_question(question)
      unless response.chomp == correct_answer
        die "I didn't think so.", "Aborting!", 1
      end
      ui.info("")
    end

    # list of problems encountered
    attr_accessor :problems
    # register that a problem was encountered
    def has_problem(desc)
      (@problems||=[]) << desc
    end
    # healthy if no problems
    def healthy?() problems.blank? ; end

    def exit_if_unhealthy!
      return if healthy?
      problems.each do |problem|
        if problem.respond_to?(:call)
          problem.call
        else
          ui.warn(problem)
        end
      end
      exit(2) if not healthy?
    end

    #
    # Announce a new section of tasks
    #
    def section(desc, *style)
      style = [:blue] if style.empty?
      ui.info(ui.color(desc, *style))
    end

    def die *args
      Ironfan.die(*args)
    end

    module ClassMethods
      def sub_command
        self.to_s.gsub(/^.*::/, '').gsub(/^Cluster/, '').downcase
      end

      def import_banner_and_options(klass, options={})
        options[:except] ||= []
        deps{ klass.load_deps }
        klass.options.sort.each do |name, info|
          next if options.include?(name) || options[:except].include?(name)
          option name, info
        end
        options[:description] ||= "#{sub_command} all servers described by given cluster slice"
        banner "knife cluster #{"%-11s" % sub_command} CLUSTER[-FACET[-INDEXES]] (options) - #{options[:description]}"
      end
    end
    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end

    protected

    def ensure_common_environment(target)
      environments = target.environments
      if environments.length > 1
        ui.error "You cannot bootstrap machines in multiple chef environments: got #{environments.inspect} from #{target.map(&:name)}"
        ui.error "Re-run this command on each subgroup of machines that share an environment"
        raise StandardError, "Cannot bootstrap multiple chef environments"
      end
      Chef::Config[:environment] = environments.first
    end

    def with_verbosity(num)
      yield if config[:verbosity] >= num
    end
  end
end
