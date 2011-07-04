require 'chef/knife'

require 'awesome_print'

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

    def h
      @highline ||= HighLine.new
    end

    def die *args
      ClusterChef.die(*args)
    end

    # What headings to show in server slice tables by default
    def display_style
      config[:detailed] ? :detailed : :default
    end

    #
    # Put Fog into mock mode if --dry_run
    #
    def enable_dry_run
      Fog.mock!
      Fog::Mock.delay = 0
    end

    def sub_command
      self.class.to_s.gsub(/^.*::/, '').gsub!(/^Cluster/, '').downcase
    end

    def slice_from_args( *predicate )
      ClusterChef.slice(* predicate)
    end

    def confirm_or_exit str
      response = STDIN.readline
      unless response.chomp == str
        die "I didn't think so.", "Aborting!", 1
      end
      puts
    end

    # Show a pretty progress bar while we wait for a set of threads to finish.
    def progressbar_for_threads threads
      puts "\nWaiting for servers:"
      total      = threads.length
      remaining  = threads.select(&:alive?)
      start_time = Time.now
      until remaining.empty?
        remaining.select!(&:alive?)
        Formatador.redisplay_progressbar(total - remaining.length, total, {:started_at => start_time })
        sleep 1
      end
      # Collapse the threads
      threads.each(&:join)
      puts ''
    end

    def bootstrapper(node, hostname)
      bootstrap = Chef::Knife::Bootstrap.new
      bootstrap.config.merge!(config)

      Chef::Log.debug self.class.options

      bootstrap.name_args               = [ hostname ]
      bootstrap.config[:run_list]       = node.run_list
      bootstrap.config[:ssh_user]       = config[:ssh_user]       || node.cloud.ssh_user
      bootstrap.config[:identity_file]  = config[:identity_file]  || node.cloud.ssh_identity_file
      bootstrap.config[:distro]         = config[:distro]         || node.cloud.bootstrap_distro
      bootstrap.config[:use_sudo]       = true unless config[:use_sudo] == false
      Chef::Log.debug JSON.pretty_generate(config)
      Chef::Log.debug JSON.pretty_generate(bootstrap.config)
      bootstrap
    end

    def run_bootstrap(node, hostname)
      begin
        bootstrapper(node, hostname).run
      rescue StandardError => e
        warn e
        warn e.backtrace
        warn ""
        warn node.inspect
        warn ""
      end
    end


  end
end
