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
require 'terminal-table/import'

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
            servers = facet.servers[index] ? [ facet.servers[index] ] : []
          else
            servers = facet.servers.values
          end
        else
          servers = cluster.servers
        end
        
        #
        # Display server info
        #

        # [ cluster, fog, chef ]


        defined_data = servers.map do |svr|
          main_part = [ svr.chef_node_name,
                        svr.facet_name,
                        svr.facet_index, 
                        svr.chef_node ? "yes" : "NO" ] 
          if svr.fog_server
            fog_part = [ svr.fog_server.id, 
                         svr.fog_server.state, 
                         svr.fog_server.public_ip_address ] 
          else
            fog_part = [ { :value => "not started", :colspan => 3 } ]
          end
          
          main_part + fog_part
        end
        
       
        puts "Information for cluster #{cluster_name}"
        if defined_data.empty?
          puts "Nothing to report"
        else
          puts table(["Node Name","Facet","Index","Chef?","AWS ID","State","Address"], *defined_data)
        end

        if facet.nil?
          undefined_data = cluster.undefined_servers.map do |hash|
            chef_node = hash[:chef_node]
            fog_server = hash[:fog_server]
            if chef_node
              chef_part = [ chef_node.node_name, chef_node.facet_name, chef_node.facet_index ]
            else
              chef_part = [ {:value=>"", :colspan => 3 } ]
            end
            
            if fog_server
              fog_part = [ fog_server.id, fog_server.state, fog_server.public_ip_address ]
            else
              fog_part = [ { :value => "not started", :colspan => 3 } ]
            end
            
            chef_part + fog_part
          end

          unless undefined_data.empty?
            puts
            puts "Cluster contains undefined servers"
            puts table(["Node Name", "Facet", "Index", "AWS ID", "State", "Address"], *undefined_data )
          end
        end
        
      end


    end    
  end
end
