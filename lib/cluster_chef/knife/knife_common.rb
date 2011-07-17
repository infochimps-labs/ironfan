require 'chef/knife'

#require 'awesome_print'

module ClusterChef
  module KnifeCommon

    def self.load_deps
      require 'highline'
      require 'readline'
      require 'formatador'
      require 'chef/node'
      require 'chef/api_client'
      require 'fog'
    end

    def load_cluster_chef
      $: << Chef::Config[:cluster_chef_path]+'/lib'
      require 'cluster_chef/script'
      $stdout.sync = true
    end

    def get_slice( *predicate )
      target = ClusterChef.slice(* predicate)
      #target.cluster.discover!
      target
    end

    # method to nodes should be filtered on
    def slice_criterion
      :exists?
    end

    # override in subclass to confirm risky actions
    def confirm_execution *args
      # pass
    end

    #
    # Get a slice of nodes matching the given filter
    #
    # @example
    #    target = get_slice_where(:created?, *@name_args)
    #
    def get_slice_where(meth, *predicate )
      full_target = get_slice(*predicate)
      display(full_target) do |svr|
        result = svr.send(meth)
        { meth.to_s => (result ? "[blue]#{result}[reset]" : '-' ) }
      end
      full_target.select(&meth.to_sym)
    end

    # passes target to ClusterSlice#display, will show headings in server slice
    # tables based on the --detailed flag
    def display target, display_style=nil, &block
      display_style ||= (config[:detailed] ? :detailed : :default)
      target.display(display_style, &block)
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
    def progressbar_for_threads threads
      puts "\nWaiting for servers:"
      total      = threads.length
      remaining  = threads.select(&:alive?)
      start_time = Time.now
      until remaining.empty?
        remaining = remaining.select(&:alive?)
        if config[:verbosity]
          puts "waiting: #{total - remaining.length} / #{total}, #{(Time.now - start_time).to_i}s"
          sleep 3
        else
          ap config
          Formatador.redisplay_progressbar(total - remaining.length, total, {:started_at => start_time })
          sleep 1
        end
      end
      # Collapse the threads
      threads.each(&:join)
      puts ''
    end

    def bootstrapper(node, hostname)
      bootstrap = Chef::Knife::Bootstrap.new
      bootstrap.config.merge!(config)

      bootstrap.name_args               = [ hostname ]
      bootstrap.config[:node]           = node
      bootstrap.config[:run_list]       = node.run_list
      bootstrap.config[:ssh_user]       = config[:ssh_user]       || node.cloud.ssh_user
      bootstrap.config[:attribute]      = config[:attribute]
      bootstrap.config[:identity_file]  = config[:identity_file]  || node.cloud.ssh_identity_file
      bootstrap.config[:distro]         = config[:distro]         || node.cloud.bootstrap_distro
      bootstrap.config[:use_sudo]       = true unless config[:use_sudo] == false
      bootstrap.config[:chef_node_name] = node.fullname

      Chef::Log.debug JSON.pretty_generate(bootstrap.config)
      bootstrap
    end

    def run_bootstrap(node, hostname)
      bs = bootstrapper(node, hostname)
      if config[:skip].to_s == 'true'
        puts "Skipping: bootstrapp #{hostname} with #{JSON.pretty_generate(bs.config)}"
        return
      end
      begin
        bs.run
      rescue StandardError => e
        warn e
        warn e.backtrace
        warn ""
        warn node.inspect
        warn ""
      end
    end

    #
    # Utilities
    #

    def sub_command
      self.class.sub_command
    end

    def confirm_or_exit str
      response = STDIN.readline
      unless response.chomp == str
        die "I didn't think so.", "Aborting!", 1
      end
      puts
    end

    def h
      @highline ||= HighLine.new
    end

    def die *args
      ClusterChef.die(*args)
    end

    module ClassMethods
      def sub_command
        self.to_s.gsub(/^.*::/, '').gsub!(/^Cluster/, '').downcase
      end

      def import_banner_and_options klass, options={}
        options[:except] ||= []
        klass.options.each do |name, info|
          next if options.include?(name) || options[:except].include?(name)
          option name, info
        end
        banner "knife cluster #{sub_command} CLUSTER_NAME [FACET_NAME [INDEXES]] (options)"

        deps do
          klass.load_deps
        end
      end
    end
    def self.included base
      base.class_eval do
        extend ClassMethods
      end
    end
  end
end
