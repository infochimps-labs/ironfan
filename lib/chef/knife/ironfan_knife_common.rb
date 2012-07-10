require 'chef/knife'

module Ironfan
  module KnifeCommon

    def self.load_deps
      require 'formatador'
      require 'chef/node'
      require 'chef/api_client'
      require 'fog'
    end

    def load_ironfan
      $LOAD_PATH << File.join(Chef::Config[:ironfan_path], '/lib') if Chef::Config[:ironfan_path]
      require 'ironfan'
      $stdout.sync = true
      Ironfan.ui          = self.ui
      self.config[:cloud] = Chef::Config[:cloud] if Chef::Config.has_key?(:cloud)
      Ironfan.chef_config = self.config
    end

    #
    # A slice of a cluster:
    #
    # @param [String] cluster_name  -- cluster to slice
    # @param [String] facet_name    -- facet to slice (or nil for all in cluster)
    # @param [Array, String] slice_indexes -- servers in that facet (or nil for all in facet).
    #   You must specify a facet if you use slice_indexes.
    #
    # @return [Ironfan::ServerSlice] the requested slice
    def get_slice(slice_string, *args)
      if not args.empty?
        slice_string = [slice_string, args].flatten.join("-")
        ui.info("")
        ui.warn("Please specify server slices joined by dashes and not separate args:\n\n  knife cluster #{sub_command} #{slice_string}\n\n")
      end
      cluster_name, facet_name, slice_indexes = slice_string.split(/[\s\-]/, 3)
      ui.info("Inventorying servers in #{predicate_str(cluster_name, facet_name, slice_indexes)}")
      cluster = Ironfan.load_cluster(cluster_name)

      # FIXME: Temporary discovery coding, running alongside current active cluster
      #   to compare their results. This loads the parallel cluster definition that
      #   was built via load_cluster above.
      dsl = Ironfan.class_variable_get(:@@clusters)[cluster_name]
#       pp dsl
#       pp dsl.facets.values
#       pp dsl.facet(:nfs).server(0).resolve.volumes.each{|vn,v|p v.object_id}
#       dsl.facets.each{|fn,f| f.servers.each{|sn,s| pp s.resolve.volumes.values.each{|v|p v.object_id} }}
#       pp dsl.facet(:nfs).server(0).resolve.volumes.values.each{|v|p v.object_id}
#       dsl.facets.each {|n,server| pp server}
#       raise 'hell'
      broker = Ironfan::ProviderBroker.new
      machines = broker.discover(dsl)
      result = machines.select(facet_name, slice_indexes)

      cluster.resolve!
      cluster.discover!
      cluster.slice(facet_name, slice_indexes)
    end

    def predicate_str(cluster_name, facet_name, slice_indexes)
      [ "#{ui.color(cluster_name, :bold)} cluster",
        (facet_name    ? "#{ui.color(facet_name, :bold)} facet"      : "#{ui.color("all", :bold)} facets"),
        (slice_indexes ? "servers #{ui.color(slice_indexes, :bold)}" : "#{ui.color("all", :bold)} servers")
      ].join(', ')
    end

    # method to nodes should be filtered on
    def relevant?(server)
      server.exists?
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
      display(full_target) do |svr|
        rel = relevant?(svr)
        { :relevant? => (rel ? "[blue]#{rel}[reset]" : '-' ) }
      end
      full_target.select{|svr| relevant?(svr) }
    end

    # passes target to ClusterSlice#display, will show headings in server slice
    # tables based on the --verbose flag
    def display(target, display_style=nil, &block)
      display_style ||= (config[:verbosity] == 0 ? :default : :expanded)
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

    def bootstrapper(server, hostname)
      bootstrap = Chef::Knife::Bootstrap.new
      bootstrap.config.merge!(config)

      bootstrap.name_args               = [ hostname ]
      bootstrap.config[:node]           = server
      bootstrap.config[:run_list]       = server.combined_run_list
      bootstrap.config[:ssh_user]       = config[:ssh_user]       || server.cloud.ssh_user
      bootstrap.config[:attribute]      = config[:attribute]
      bootstrap.config[:identity_file]  = config[:identity_file]  || server.cloud.ssh_identity_file
      bootstrap.config[:distro]         = config[:distro]         || server.cloud.bootstrap_distro
      bootstrap.config[:use_sudo]       = true unless config[:use_sudo] == false
      bootstrap.config[:chef_node_name] = server.fullname
      bootstrap.config[:client_key]     = server.client_key.body  if server.client_key.body

      bootstrap
    end

    def run_bootstrap(node, hostname)
      bs = bootstrapper(node, hostname)
      if config[:skip].to_s == 'true'
        ui.info "Skipping: bootstrapp #{hostname} with #{JSON.pretty_generate(bs.config)}"
        return
      end
      begin
        bs.run
      rescue StandardError => e
        ui.warn e
        ui.warn e.backtrace
        ui.warn ""
        ui.warn node.inspect
        ui.warn ""
      end
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
  end
end
