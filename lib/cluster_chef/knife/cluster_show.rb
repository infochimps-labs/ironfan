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
    class ClusterShow < Knife
      include ClusterChef::KnifeCommon

      deps do
        require 'chef/node'
        require 'chef/api_client'
        require 'fog'
        ClusterChef::KnifeCommon.load_deps
      end

      banner "knife cluster show CLUSTER_NAME FACET_NAME INDEX (options)"
      option :dry_run,
        :long => "--dry-run",
        :description => "Don't really run, just use mock calls"

      def run
        ELAPSED_TIME(self.class, "run")

        load_cluster_chef
        die(banner) if @name_args.empty?
        enable_dry_run if config[:dry_run]

        # Load the cluster/facet/slice/whatever
        target = server_group(* @name_args)
        servers = target.servers

        # Create a slice of servers that are actually in defined facets
        servers = target.servers.select{|svr| target.cluster.has_facet?(svr.facet_name) }
        ClusterChef::ClusterSlice.new( target.cluster, servers ).display

        # If the cluster discovery failed to put everything into its correct
        # place, we have some servers that do not fit into the regular boxes.
        undefined_data = target.cluster.undefined_servers.map do |hash|
          chef_node  = hash[:chef_node]
          fog_server = hash[:fog_server]
          x = {}

          if chef_node
            x["Node"]  = chef_node[:node_name]
            x["Facet"] = chef_node[:facet_name]
            x["Index"] = chef_node[:facet_index]
            x["Chef?"] = (chef_node ? "yes" : "[red]no[reset]")
          end

          if fog_server
            x["InstanceID"]  = fog_server.id
            x["State"]   = fog_server.state
            x["Public IP"] = fog_server.public_ip_address
            x["Private IP"] = fog_server.private_ip_address
          else
            x["State"]  = "not running"
          end
          x
        end

        unless undefined_data.empty?
          puts
          Formatador.display_line "[red]Cluster contains undefined servers:[reset]"
          Formatador.display_compact_table(  undefined_data.sort_by {|x| "#{x["Facet"]}-#{x["Index"]}"},
                                             ["Node", "Facet", "Index", "Chef?", "InstanceID", "State", "Public IP", "Private IP"] )
        end
      end
    end
  end
end
