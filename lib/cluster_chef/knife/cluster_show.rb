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
        target = slice_from_args(* @name_args)

        # servers = target.servers
        # servers = target.servers.select{|svr| target.cluster.has_facet?(svr.facet_name) }

        # Create a slice of servers that are actually in defined facets
        headings = ["Name", "Chef?", "InstanceID", "State", "Public IP", "Created At"]
        headings << "Bogus" # if target.has_bogus_servers
        target.display(headings)

        ClusterChef::ServerSlice.new(target.cluster, ClusterChef::Server.all.values).display

        ap target.cluster.cluster_name

        ap target.cluster.facets

        target.cluster.facets.each do |nm, facet|
          ap facet.servers
          ap facet.all_servers
        end

        ap target

      end
    end
  end
end
