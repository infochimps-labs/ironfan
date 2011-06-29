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
    class ClusterStart < Knife
      deps do
        require 'chef/json_compat'
        require 'tempfile'
        require 'highline'
        require 'net/ssh'
        require 'net/ssh/multi'
        Chef::Knife::Ssh.load_deps
      end rescue nil

      banner "knife cluster start CLUSTER_NAME FACET_NAME (options)"

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
        raise "Start the cluster as: knife cluster start CLUSTER_NAME FACET_NAME (options)" if cluster_name.nil? #blank?

        cluster = ClusterChef.load_cluster( cluster_name )

        cluster.resolve!
        target = cluster

        target = cluster.facet(facet_name) if facet_name

        target.servers.each do |server|
          server.fog_server.start if server.fog_server
        end
      end
    end
  end
end
