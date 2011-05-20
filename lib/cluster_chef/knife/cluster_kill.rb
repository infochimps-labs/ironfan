#
# Author:: Chris Howe (<howech@infochimps.com>)
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
    class ClusterKill < Knife
      banner "knife cluster kill CLUSTER_NAME FACET_NAME INDEX (options)"

      attr_accessor :initial_sleep_delay

      option :dry_run,
        :long => "--dry-run",
        :description => "Don't really run, just use mock calls"

      option :undefined,
        :long => "--undefined",
        :descritption => "Kill undefined servers"

      option :no_chef,
        :long => "--no-chef",
        :descrition => "Do not delete chef nodes"
      
      option :no_fog,
        :long => "--no-fog",
        :description => "Do not delete any fog servers"

      option :no_defined,
        :long => "--no-defined",
        :description => "Do not delete any defined nodes (use with --undefined to just clean up)"
        
      option :yes,
        :long => "--yes",
        :description => "Skip confirmation that you want to delete the cluster."

      option :really,
        :long => "--really",
        :description => "Skip the second confirmation that you REALLY want to delete the cluster."

      option :no,
        :long => "--no",
        :description => "No matter what, do not delete anything."

      def h
        @highline ||= HighLine.new
      end

      def run
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'
        require 'chef/node'

        # TODO: this is a hack - remove when ClusterChef is deployed as a gem
        $: << Chef::Config[:cluster_chef_path]+'/lib'

        # TODO: this is a hack - should be moved to some kind of configuration
        #       controllable by the user, perhaps in a knife.rb file. Needs to
        #       be fixed as a part of separating cluster configuration from
        #       ClusterChef gem.  However, it is currently required to get 
        #       ClusterChef.load_cluster to work right.
        $: << Chef::Config[:cluster_chef_path]

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
        cluster_name, facet_name, index = @name_args
        
        cluster = ClusterChef.load_cluster( cluster_name )        
        facet = cluster.facet(facet_name) if facet_name

        servers = [] 

        cluster.resolve!
        
        chef_nodes = []
        fog_servers = []

        unless config[:no_defined]
          if facet          
            if index
              chef_nodes  = facet.server_by_index[index] ? [ facet.server[index].chef_node ] : []
              fog_servers = facet.server_by_index[index] ? [ facet.server[index].fog_server ] : []
            else
              chef_nodes  = facet.chef_nodes
              fog_servers = facet.fog_servers
            end
          else
            cluster.servers.each do |server|
              chef_nodes.push server.chef_node
              fog_servers.push server.fog_server
            end
          end
        end

        if config[:undefined]
          cluster.undefined_servers.each do |hash|
            chef_nodes.push hash[:chef_node]
            fog_servers.push hash[:fog_server]
          end
        end
        
        chef_nodes.uniq!.compact!
        fog_servers.uniq!.compact!
        
        if config[:no_chef]
          chef_nodes = []
        end

        if config[:no_fog]
          fog_servers = []
        end
         
        
        if chef_nodes.empty? && fog_servers.empty?
          puts
          puts "Nothing to delete."
          puts "Exiting."
          puts
          exit 1
        end


        puts "WARNING!!!!"
        puts
        unless chef_nodes.empty?
          puts "This command will delete the following chef nodes: "
          puts chef_nodes.map {|n| n.node_name}.join(" ")
          puts
        end
        unless fog_servers.empty?
          puts "This command will terminate the following servers: "
          puts fog_servers.map {|s| s.id}.join(" ")
          puts
        end
        puts "Are you absolutely certain that you want to perform this action? (Type 'Yes' to confirm)"
 
        unless config[:yes]
          confirm = STDIN.readline
          if confirm.chomp != "Yes"
            puts "I didn't think so."
            puts "Aborting!"
            exit 1
          end
        else
          puts "Bypassing confirmation."
        end
          
        unless config[:really]
          puts "..."
          sleep 3
          puts "There is no going back. When these nodes and instances are deleted, they will be gone forever. Are you really sure? (Type 'YES!' to confirm)"
          confirm = STDIN.readline
          if confirm.chomp != "YES!"
            puts "I knew you would back out!"
            puts "Aborting!"
            exit 1
          end
        else
          puts "Bypassing secondary confirmation. I hope you know what you are doing..."
        end
     
        exit 1 if config[:no]


        fog_servers.each {|fog_server| fog_server.destroy; puts "terminating #{fog_server.id}" }
        chef_nodes.each {|node| delete_object(Chef::Node, node.node_name) }

   
      end
    end    
  end
end
