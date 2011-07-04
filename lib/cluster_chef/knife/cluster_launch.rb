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

      banner "knife cluster launch CLUSTER_NAME FACET_NAME (options)"
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

      def run
        load_cluster_chef
        die(banner) if @name_args.empty?
        enable_dry_run if config[:dry_run]

        #
        # Load the facet
        #
        target       = server_group(* @name_args)
        cluster      = target.cluster
        warn_or_die_on_undefined_servers(target, cluster.undefined_servers) unless cluster.undefined_servers.empty?

        uncreated_servers = target.uncreated_servers
        if uncreated_servers.servers.empty? then
          show_cluster_launch_banner(target)
          die "", "#{h.color("All servers are running -- not launching any.",:blue)}", ""
        end

        # TODO: Should we make a key pair when the security key has not yet been created ?!?!?!?
        # We need to dummy up a key_pair in simulation mode, not doing it fr'eals
        if config[:dry_run] then ClusterChef.connection.key_pairs.create(:name => cluster.name) ; end

        # Make security groups
        target.security_groups.each{|name,group| group.run }

        # Launch servers
        uncreated_servers.create_servers
        show_cluster_launch_banner(uncreated_servers)

        # As each server finishes, configure it
        watcher_threads = uncreated_servers.servers.map do |s|
          Thread.new(s) do |cc_server|

            # Hook up external assets
            cc_server.create_tags
            cc_server.fog_server.wait_for{ ready? }
            cc_server.attach_volumes

            # Try SSH
            unless config[:dry_run]
              nil until tcp_test_ssh(cc_server.fog_server.dns_name){ sleep @initial_sleep_delay ||= 10  }
            end

            # Run Bootstrap
            if config[:bootstrap]
              run_bootstrap(cc_server, cc_server.fog_server.dns_name)
            end
          end
        end

        progressbar_for_threads(watcher_threads)

        show_cluster_launch_banner(uncreated_servers)
      end

      def show_cluster_launch_banner servers
        servers.display(["Name", "InstanceID", "Flavor", "Image", "AZ", "Public IP", "Private IP", "Created At"] )
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

      def warn_or_die_on_undefined_servers(target_servers, bad_servers)
        # FIXME: refactor all the banners running around all over the place
        puts
        puts "Cluster has servers in a transitional or undefined state. These guys are cool:"
        puts
        show_cluster_launch_banner target_servers
        puts
        puts "These guys are lame:"
        puts
        bad_servers.each{|svr| puts svr.inspect }
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
