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

require 'socket'
require 'chef/knife'
require 'json'
require 'formatador'
require 'time'

class Chef
  class Knife
    class ClusterLaunch < Knife

      deps do
        Chef::Knife::Bootstrap.load_deps
      end

      deps do
        require 'chef/knife/core/bootstrap_context'
        require 'chef/json_compat'
        require 'tempfile'
        require 'highline'
        require 'net/ssh'
        require 'net/ssh/multi'
        Chef::Knife::Ssh.load_deps
      end rescue nil

      banner "knife cluster launch CLUSTER_NAME FACET_NAME (options)"

      attr_accessor :initial_sleep_delay

      option :dry_run,
        :long => "--dry-run",
        :description => "Don't really run, just use mock calls"

      option :bootstrap,
        :long => "--bootstrap",
        :description => "Also bootstrap the launched node"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems when bootstrapping"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use when bootstrapping",
        :default => false

      option :force,
        :long => "--force",
        :description => "Perform launch operations even if it may not be safe to do so."

      def h
        @highline ||= HighLine.new
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

      def run
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'
        $: << Chef::Config[:cluster_chef_path]+'/lib'
        require 'cluster_chef'
        $stdout.sync = true

        #
        # Put Fog into mock mode if --dry_run
        #
        if config[:dry_run]
          Fog.mock!
          Fog::Mock.delay = 0
        end

        #
        # Load the facet
        #
        target = ClusterChef.get_cluster_slice *@name_args
        cluster = target.cluster
        cluster_name = cluster.cluster_name

        cluster.resolve!

        unless cluster.undefined_servers.empty?
          puts
          puts "Cluster has servers in a transitional or undefined state."
          unless config[:force]
            puts "Launch operations may be unpredictable under these circumstances."
            puts "You should wait for the cluster to stabilize, fix the undefined server problems"
            puts "(run \"knife cluster show CLUSTER\" to see what the problems are), or launch"
            puts "the cluster anyway using the --force option."
            puts
            exit 1
          end
          puts
          puts "--force specified"
          puts "Proceeding to launch anyway. This may produce undesired results."
          puts
        end

        #
        # Make access key ?
        #

        # TODO: do the right thing when the security key has not yet been created ?!?!?!?

        #
        # Make security groups
        #
        target.security_groups.each{|name,group| group.run }

        #
        # Launch servers
        #
        uncreated_servers = target.uncreated_servers

        if uncreated_servers.servers.empty?
          puts
          puts "#{h.color("No servers created!!",:red)}"
          puts
          exit 1
        end

        # need to dummy up a key_pair in simulation mode
        if config[:dry_run] then ClusterChef.connection.key_pairs.create(:name => cluster_name) ; end

        uncreated_servers.create_servers

        uncreated_servers.display(["Instance", "Flavor", "Image", "A. Zone", "SSH Key", "Public IP", "Private IP"] ) do |svr|
          s = svr.fog_server
          { "Instance"          => (s.id && s.id.length > 0) ? s.id : "???", # We should really have an id by this time
            "Flavor"            => s.flavor_id,
            "Image"             => s.image_id,
            "A. Zone"           => s.availability_zone,
            "SSH Key"           => s.key_name,
            "Public IP"         => s.public_ip_address,
            "Private IP"        => s.private_ip_address,
          }
        end


        puts "Waiting for servers:"

        watcher_threads = uncreated_servers.servers.map do |s|
          Thread.new(s) do  |cc_server|
            server = cc_server.fog_server
            cc_server.create_tags
            server.wait_for { ready? }
            cc_server.attach_volumes
            unless config[:dry_run]
              nil until tcp_test_ssh(server.dns_name){ sleep @initial_sleep_delay ||= 10  }
            end
            if config[:bootstrap]
              begin
                bootstrap_for_node(cc_server).run
              rescue StandardError => e
                warn e
                warn e.backtrace
              end
            end
          end
        end


        # Show a pretty progress bar
        count = 0
        total = watcher_threads.length
        remaining = watcher_threads.select {|s| s.alive?}
        count = remaining.length
        start_time = Time.now
        while count > 0
          remaining.reject! {|s| not s.alive?}
          count = remaining.length
          Formatador.redisplay_progressbar(total - count,total, {:started_at => start_time })
          sleep 1
        end

        # Collapse the threads
        watcher_threads.each do |thr|
          thr.join
        end

        puts
        uncreated_servers.display(["Instance", "Flavor", "Image", "A. Zone", "SSH Key", "Public IP", "Private IP"] ) do |svr|
          s = svr.fog_server
          { "Instance"          => (s.id && s.id.length > 0) ? s.id : "???", # We should really have an id by this time
            "Flavor"            => s.flavor_id,
            "Image"             => s.image_id,
            "A. Zone"           => s.availability_zone,
            "SSH Key"           => s.key_name,
            "Public IP"         => s.public_ip_address,
            "Private IP"        => s.private_ip_address,
          }
        end
      end

      def bootstrap_for_node(node)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args               = [node.fog_server.dns_name]
        bootstrap.config[:run_list]       = config[:run_list]       || node.facet.run_list
        bootstrap.config[:ssh_user]       = config[:ssh_user]       || node.cloud.ssh_user
        bootstrap.config[:identity_file]  = config[:identity_file]  || node.cloud.ssh_identity_file
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || node.fog_server.id
        bootstrap.config[:distro]         = config[:distro]         || node.cloud.bootstrap_distro
        bootstrap.config[:prerelease]     = config[:prerelease]
        bootstrap.config[:use_sudo]       = true
        bootstrap.config[:template_file]  = config[:template_file]
        Chef::Log.debug bootstrap.config.inspect
        bootstrap
      end

    end
  end
end
