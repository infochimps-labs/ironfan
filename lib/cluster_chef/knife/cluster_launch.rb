#
# Author:: Philip (flip) Kromer (<flip@infochimps.com>)
# Copyright:: Copyright (c) 2011 Infochimps, Inc
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path(File.dirname(__FILE__)+"/knife_common.rb")

class Chef
  class Knife
    class ClusterLaunch < Knife
      include ClusterChef::KnifeCommon

      deps do
        require 'time'
        require 'socket'
        ClusterChef::KnifeCommon.load_deps
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife cluster launch CLUSTER_NAME [FACET_NAME [INDEXES]] (options)"
      [ :ssh_port, :ssh_password, :identity_file, :use_sudo, :no_host_key_verify,
        :prerelease, :bootstrap_version, :template_file,
      ].each do |name|
        option name, Chef::Knife::Bootstrap.options[name]
      end
      option :dry_run,
        :long => "--dry-run",
        :description => "Don't really run, just use mock calls"
      option :bootstrap,
        :long => "--bootstrap",
        :description => "Also bootstrap the launched node"
      option :bootstrap_runs_chef_client,
        :long => "--bootstrap-runs-chef-client",
        :description => "If bootstrap is invoked, will do the initial run of chef-client in the bootstrap script"
      option :force,
        :long => "--force",
        :description => "Perform launch operations even if it may not be safe to do so."
      option :detailed,
        :long => "--detailed",
        :description => "Show detailed info on servers"
      option :abort,
        :long => "--abort",
        :description => "Abort before actually launching (though this might still hit the outside world, eg sec grps)"

      def run
        load_cluster_chef
        die(banner) if @name_args.empty?
        configure_dry_run

        #
        # Load the facet
        #
        full_target = get_slice(*@name_args)
        display(full_target)
        target = full_target.select(&:launchable?)

        warn_or_die_on_bogus_servers(full_target) unless full_target.bogus_servers.empty?

        die("", "#{h.color("All servers are running -- not launching any.",:blue)}", "", 1) if target.empty?

        # We need to dummy up a key_pair in simulation mode, not doing it fr'eals
        # You must to do this manually in real life -- must save the file, etc.
        if config[:dry_run] then ClusterChef.connection.key_pairs.create(:name => target.cluster.name) ; end

        # This will create/update any roles
        target.sync_roles

        # Make security groups
        puts
        puts "Making security groups:"
        full_target.security_groups.each{|name,group| group.run }

        # Launch servers
        die "Aborting! (--abort given)" if config[:abort]
        puts
        puts "Launching machines:"
        target.create_servers

        # This will create/update any roles
        target.sync_roles

        puts
        display(target)

        # As each server finishes, configure it
        watcher_threads = target.map do |s|
          Thread.new(s) do |cc_server|
            perform_after_launch_tasks(cc_server)
          end
        end

        progressbar_for_threads(watcher_threads)

        display(target)
      end

      def display(target)
        super(target, ["Name", "InstanceID", "State", "Flavor", "Image", "AZ", "Public IP", "Private IP", "Created At", 'Volumes', 'Elastic IP']) do |svr|
          { 'launchable?' => (svr.launchable? ? "[blue]#{svr.launchable?}[reset]" : '-' ), }
        end
      end

      def perform_after_launch_tasks(server)
        # Hook up external assets
        server.create_tags

        # Pre-populate information in chef
        server.sync_to_chef

        # Wait for node creation on amazon side
        server.fog_server.wait_for{ ready? }

        # Attach volumes, etc
        server.sync_to_cloud

        # Try SSH
        unless config[:dry_run]
          nil until tcp_test_ssh(server.fog_server.dns_name){ sleep @initial_sleep_delay ||= 10  }
        end

        # Run Bootstrap
        if config[:bootstrap]
          run_bootstrap(server, server.fog_server.dns_name)
        end
      end

      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, 22)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def warn_or_die_on_bogus_servers(target)
        puts
        puts "Cluster has servers in a transitional or undefined state (shown as 'bogus'):"
        puts
        display(target)
        puts
        unless config[:force]
          die(
            "Launch operations may be unpredictable under these circumstances.",
            "You should wait for the cluster to stabilize, fix the undefined server problems",
            "(run \"knife cluster show CLUSTER\" to see what the problems are), or launch",
            "the cluster anyway using the --force option.", "", -2)
        end
        puts
        puts "--force specified"
        puts "Proceeding to launch anyway. This may produce undesired results."
        puts
      end

    end
  end
end
