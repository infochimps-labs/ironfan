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
        :long        => "--dry-run",
        :description => "Don't really run, just use mock calls",
        :boolean     => true,
        :default     => false
      option :force,
        :long        => "--force",
        :description => "Perform launch operations even if it may not be safe to do so. Default false",
        :boolean     => true,
        :default     => false

      option :bootstrap,
        :long        => "--[no-]bootstrap",
        :description => "Also bootstrap the launched node (default is NOT to bootstrap)",
        :boolean     => true,
        :default     => false
      option :bootstrap_runs_chef_client,
        :long        => "--[no-]bootstrap-runs-chef-client",
        :description => "If bootstrap is invoked, the bootstrap script causes an initial run of chef-client (default true).",
        :boolean     => true,
        :default     => true

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

        die("", "#{ui.color("All servers are running -- not launching any.",:blue)}", "", 1) if target.empty?

        # Pre-populate information in chef
        section("Sync'ing to chef and cloud")
        target.sync_to_cloud
        target.sync_to_chef

        # Make security groups
        section("Making security groups")
        full_target.security_groups.each{|name,group| group.run }

        # Launch servers
        section("Launching machines", :green)
        target.create_servers

        ui.info("")
        display(target)

        # As each server finishes, configure it
        watcher_threads = target.parallelize do |svr|
          perform_after_launch_tasks(svr)
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
        ui.info("")
        ui.info "Cluster has servers in a transitional or undefined state (shown as 'bogus'):"
        ui.info("")
        display(target)
        ui.info("")
        unless config[:force]
          die(
            "Launch operations may be unpredictable under these circumstances.",
            "You should wait for the cluster to stabilize, fix the undefined server problems",
            "(run \"knife cluster show CLUSTER\" to see what the problems are), or launch",
            "the cluster anyway using the --force option.", "", -2)
        end
        ui.info("")
        ui.info "--force specified"
        ui.info "Proceeding to launch anyway. This may produce undesired results."
        ui.info("")
      end

    end
  end
end
