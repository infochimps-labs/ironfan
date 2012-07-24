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

require File.expand_path('ironfan_knife_common', File.dirname(File.realdirpath(__FILE__)))
require File.expand_path('cluster_bootstrap',    File.dirname(File.realdirpath(__FILE__)))

class Chef
  class Knife
    class ClusterLaunch < Knife
      include Ironfan::KnifeCommon

      deps do
        require 'time'
        require 'socket'
        Chef::Knife::ClusterBootstrap.load_deps
      end

      banner "knife cluster launch      CLUSTER[-FACET[-INDEXES]] (options) - Creates chef node and chef apiclient, pre-populates chef node, and instantiates in parallel their cloud machines. With --bootstrap flag, will ssh in to machines as they become ready and launch the bootstrap process"
      [ :ssh_port, :ssh_user, :ssh_password, :identity_file, :use_sudo,
        :prerelease, :bootstrap_version, :template_file, :distro,
        :bootstrap_runs_chef_client, :host_key_verify
      ].each do |name|
        option name, Chef::Knife::ClusterBootstrap.options[name]
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

      def run
        load_ironfan
        die(banner) if @name_args.empty?
        configure_dry_run

        #
        # Load the facet
        #
        full_target = get_slice(*@name_args)
        display(full_target)
        target = full_target.select(&:launchable?)

        warn_or_die_on_bogus_servers(full_target) unless full_target.select(&:bogus?).empty?

        die("", "#{ui.color("All machines are running -- not launching any.",:blue)}", "", 1) if target.empty?

        # Pre-populate information in chef
        section("Sync'ing to chef and providers")
        broker.save! target

        # Launch machines
        broker.create! target

#         # As each server finishes, configure it
#         watcher_threads = target.parallelize do |svr|
#           perform_after_launch_tasks(svr)
#         end
#
#         progressbar_for_threads(watcher_threads)

        display(target)
      end

#
#       def perform_after_launch_tasks(server)
#         # Wait for node creation on amazon side
#         server.fog_server.wait_for{ ready? }
#
#         # Try SSH
#         unless config[:dry_run]
#           nil until tcp_test_ssh(server.fog_server.dns_name){ sleep @initial_sleep_delay ||= 10  }
#         end
#
#         # Make sure our list of volumes is accurate
#         Ironfan.fetch_fog_volumes
#         server.discover_volumes!
#
#         # Attach volumes, etc
#         server.sync_to_cloud
#
#         # Run Bootstrap
#         if config[:bootstrap]
#           run_bootstrap(server, server.fog_server.dns_name)
#         end
#       end
#
#       def tcp_test_ssh(hostname)
#         tcp_socket = TCPSocket.new(hostname, 22)
#         readable = IO.select([tcp_socket], nil, nil, 5)
#         if readable
#           Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
#           yield
#           true
#         else
#           false
#         end
#       rescue Errno::ETIMEDOUT
#         false
#       rescue Errno::ECONNREFUSED
#         sleep 2
#         false
#       ensure
#         tcp_socket && tcp_socket.close
#       end
#

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
