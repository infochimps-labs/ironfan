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
    class ClusterShow < Knife


      banner "knife cluster show CLUSTER_NAME FACET_NAME INDEX (options)"

      attr_accessor :initial_sleep_delay

      option :dry_run,
        :long => "--dry-run",
        :description => "Don't really run, just use mock calls"

      def h
        @highline ||= HighLine.new
      end

      def run
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'

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

        #require Chef::Config[:cluster_chef_path]+"/clusters/#{cluster_name}"
        # cluster = Chef::Config[:clusters][cluster_name]
        
        facet = cluster.facet(facet_name) if facet_name

        servers = [] 

        cluster.resolve!
        if facet          
          if index
            servers = facet.server_by_index[index] ? [ facet.server_by_index[index] ] : []
          else
            servers = facet.servers
          end
        else
          servers = cluster.servers
        end
        
        #
        # Display server info
        #

        # [ cluster, fog, chef ]


        defined_data = servers.sort{ |a,b| (a.facet_name <=> b.facet_name) *3 + (a.facet_index <=> b.facet_index) }.map do |svr|
          x = { "Node"    => svr.chef_node_name,
                "Facet"   => svr.facet_name,
                "Index"   => svr.facet_index,
                "Chef?"   => svr.chef_node ? "yes" : "[red]no[reset]",
          }

          if svr.fog_server 
            x["AWS ID"]  = svr.fog_server.id
            x["State"]   = svr.fog_server.state
            x["Address"] = svr.fog_server.public_ip_address
          else
            x["State"] = "not running"
          end

          x
        end
        
       
        puts "Information for cluster #{cluster_name}"
        if defined_data.empty?
          puts "Nothing to report"
        else
          Formatador.display_compact_table(defined_data,["Node","Facet","Index","Chef?","AWS ID","State","Address"])
        end

        if facet.nil?
          undefined_data = cluster.undefined_servers.map do |hash|
            chef_node = hash[:chef_node]
            fog_server = hash[:fog_server]
            x = {}

            if chef_node
              x["Node"]  = chef_node[:node_name]
              x["Facet"] = chef_node[:facet_name]
              x["Index"] = chef_node[:facet_index]
            end

            
            if fog_server
              x["AWS ID"]  = fog_server.id
              x["State"]   = fog_server.state
              x["Address"] = fog_server.public_ip_address
            else
              x["State"]  = "not running" 
            end
            x
          end

          unless undefined_data.empty?
            puts
            Formatador.display_line "[red]Cluster contains undefined servers[reset]"
            Formatador.display_compact_table(  undefined_data.sort_by {|x| "#{x["Facet"]}-#{x["Index"]}"},                                              ["Node", "Facet", "Index", "AWS ID", "State", "Address"])
          end
        end
      end
    end    
  end
end
