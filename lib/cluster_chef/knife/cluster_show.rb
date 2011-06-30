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
      deps do
        Chef::Knife::Bootstrap.load_deps 
      end      

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
        # Load the cluster/facet/slice/whatever
        #
        target = ClusterChef.get_cluster_slice *@name_args
        cluster = target.cluster
        cluster_name = cluster.cluster_name

        cluster.resolve!
        servers = target.servers

        #
        # Display server info
        #
        
        # Create a slice of servers that are actually in defined facets
        servers = target.servers.select { |svr| cluster.has_facet? svr.facet_name }
        ClusterChef::ClusterSlice.new( cluster, servers ).display

        # If the cluster discovery failed to put everything into its correct
        # place, we have some servers that do not fit into the regular boxes.
        undefined_data = target.cluster.undefined_servers.map do |hash|
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
          Formatador.display_compact_table(  undefined_data.sort_by {|x| "#{x["Facet"]}-#{x["Index"]}"},
                                             ["Node","Facet","Index","Chef?","AWS ID","State","Address"] )
        end
      end
    end
  end
end
