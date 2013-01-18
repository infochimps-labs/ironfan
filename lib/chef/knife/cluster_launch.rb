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

      banner "knife cluster launch      CLUSTER[-FACET[-INDEXES]] (options) - Creates chef node and chef apiclient, pre-populates chef node, and instantiates in parallel their cloud computers. With --bootstrap flag, will ssh in to computers as they become ready and launch the bootstrap process"
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
        :description => "Also bootstrap the launched machine (default is NOT to bootstrap)",
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

        die("", "#{ui.color("All computers are running -- not launching any.",:blue)}", "", 1) if target.empty?

        # If a bootstrap was requested, ensure that we will be able to perform the
        # bootstrap *before* trying to launch all of the servers in target. This
        # will save the user a lot of time if they've made a configuration mistake
        if config[:bootstrap]
          ensure_common_environment(target)
        end

        # Pre-populate information in chef
        section("Syncing to chef")
        target.save :providers => :chef

        unless target.empty?
          ui.info "Preparing shared resources:"
          all_computers(*@name_args).prepare
        end

        # Launch computers
        ui.info("")
        section("Launching computers", :green)
        display(target)
        launched = target.launch
        # As each server finishes, configure it
        Ironfan.parallel(launched) do |computer|
          if (computer.is_a?(Exception)) then ui.warn "Error launching #{computer.inspect}; skipping after-launch tasks."; next; end
          Ironfan.step(computer.name, 'launching', :white)
          perform_after_launch_tasks(computer)
        end

        if healthy?
          ui.info "Applying aggregations:"
          all_computers(*@name_args).aggregate
        end

        display(target)
      end

      def perform_after_launch_tasks(computer)
        Ironfan.step(computer.name, 'waiting for ready', :white)
        # Wait for machine creation on amazon side
        computer.machine.wait_for{ ready? }
        
        # Try SSH
        unless config[:dry_run]
          Ironfan.step(computer.name, 'trying ssh', :white)
          address = computer.machine.vpc_id.nil? ? computer.machine.public_hostname : computer.machine.public_ip_address
          nil until tcp_test_ssh(address){ sleep @initial_sleep_delay ||= 10  }
        end

        Ironfan.step(computer.name, 'final provisioning', :white)
        computer.save
        
        # Run Bootstrap
        if config[:bootstrap]
          Chef::Log.warn "UNTESTED --bootstrap"
          run_bootstrap(computer)
        end
      end

      def tcp_test_ssh(target)
        tcp_socket = TCPSocket.new(target, 22)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{target}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
	Chef::Log.debug("ssh to #{target} timed out")
        false
      rescue Errno::ECONNREFUSED
	Chef::Log.debug("ssh connection to #{target} refused")
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
	Chef::Log.debug("ssh host #{target} unreachable")
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
