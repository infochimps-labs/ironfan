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

class Chef
  class Knife
    class ClusterLaunch < Knife

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
        cluster_name, facet_name = @name_args
        raise "Launch the cluster as: knife cluster launch CLUSTER_NAME FACET_NAME (options)" if cluster_name.nil? #blank?
        require File.expand_path(Chef::Config[:cluster_chef_path]+"/clusters/defaults")
        require File.expand_path(Chef::Config[:cluster_chef_path]+"/clusters/#{cluster_name}")

        # In order to discover the complete cluster, we need to resolve the cluster
        cluster = Chef::Config[:clusters][cluster_name]
        cluster.resolve!
        
        target = cluster
        
        target = cluster.facet(facet_name) if facet_name

        # 
        # Make access key ?
        #

        # TODO: do the right thing when the security key has not yet been created ?!?!?!?

        #
        # Make security groups
        #

        # TODO: write cluster/facet/server security groups method that returns all of the relevent security groups
        target.cloud.security_groups.each{|name,group| group.run }

        #
        # Launch server
        #
        
        created_servers = target.servers.map { |s| s.create_server }.compact


        if created_servers.empty?
          puts
          puts "#{h.color("No servers created!!",:red)}"
          puts
          exit 1
        end

        config[:ssh_user]       = target.cloud.ssh_user
        config[:identity_file]  = target.cloud.ssh_identity_file
        config[:distro]         = target.cloud.bootstrap_distro
        config[:run_list]       = target.run_list

        table_rows = created_servers.map do |s|
          { "Instance"          => (s.id && s.id.length > 0) ? s.id : "???", # We should really have an id by this time
            "Flavor"            => s.flavor_id,
            "Image"             => s.image_id,
            "Availability Zone" => s.availability_zone,
            "SSH Key"           => s.key_name,
            "Public IP"         => s.public_ip_address,
            "Private IP"        => s.private_ip_address,
          }
        end
        Formatador.display_table( table_rows, ["Instance", "Flavor", "Image", "Availability Zone", "SSH Key", "Public IP", "Private IP"] )
        
        print "\n#{h.color("Waiting for servers", :magenta)}"
        watcher_threads = created_servers.map do |s| 
          Thread.new(s) do  |server|
            server.wait_for { print "."; ready? }
            #table_row = { "Instance"          => (s.id && s.id.length > 0) ? s.id : "???", # We should really have an id by this time
            #  "Flavor"            => s.flavor_id,
            #  "Image"             => s.image_id,
            #  "Availability Zone" => s.availability_zone,
            #  "SSH Key"           => s.key_name,
            #  "Public IP"         => s.public_ip_address,
            #  "Private IP"        => s.private_ip_address,
            #}
            #Formatador.display_table( [table_row], ["Instance", "Flavor", "Image", "Availability Zone", "SSH Key", "Public IP", "Private IP"] )             
            print(".") until tcp_test_ssh(server.dns_name) { sleep @initial_sleep_delay ||= 10; print("!") }
            if config[:bootstrap]
              begin
                bootstrap_for_node(server).run
              rescue StandardError => e
                warn e
                warn e.backtrace
              end
            end
          end
        end

        watcher_threads.each {|thr| thr.join; puts }
        
        table_rows = created_servers.map do |s|
          { "Instance"          => (s.id && s.id.length > 0) ? s.id : "???", # We should really have an id by this time
            "Flavor"            => s.flavor_id,
            "Image"             => s.image_id,
            "Availability Zone" => s.availability_zone,
            "SSH Key"           => s.key_name,
            "Public IP"         => s.public_ip_address,
            "Private IP"        => s.private_ip_address,
          }
        end
        Formatador.display_table( table_rows, ["Instance", "Flavor", "Image", "Availability Zone", "SSH Key", "Public IP", "Private IP"] )


#        created_servers.each do |server|
#          puts "\n"
#          puts "#{h.color("Instance ID        ", :cyan)}: #{server.id}"
#          puts "#{h.color("Flavor             ", :cyan)}: #{server.flavor_id}"
#          puts "#{h.color("Image              ", :cyan)}: #{server.image_id}"
#          puts "#{h.color("Availability Zone  ", :cyan)}: #{server.availability_zone}"
#          puts "#{h.color("Security Groups    ", :cyan)}: #{server.groups.join(", ")}"
#          puts "#{h.color("SSH Key            ", :cyan)}: #{server.key_name}"
#          puts "#{h.color("Public DNS Name    ", :cyan)}: #{server.dns_name}"
#          puts "#{h.color("Public IP Address  ", :cyan)}: #{server.public_ip_address}"
#          puts "#{h.color("Private DNS Name   ", :cyan)}: #{server.private_dns_name}"
#          puts "#{h.color("Private IP Address ", :cyan)}: #{server.private_ip_address}"
#          puts "#{h.color("Run List           ", :cyan)}: #{facet.run_list.join(', ')}"
#        end
      end

      def bootstrap_for_node(server)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args               = [server.dns_name]
        bootstrap.config[:run_list]       = config[:run_list]
        bootstrap.config[:ssh_user]       = config[:ssh_user]
        bootstrap.config[:identity_file]  = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id
        bootstrap.config[:prerelease]     = config[:prerelease]
        bootstrap.config[:distro]         = config[:distro]
        bootstrap.config[:use_sudo]       = true
        bootstrap.config[:template_file]  = config[:template_file]
        bootstrap
      end

    end
  end
end
