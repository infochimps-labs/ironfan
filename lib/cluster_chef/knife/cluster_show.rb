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

class Chef
  class Knife
    class ClusterShow < Knife

      banner "knife cluster show CLUSTER_NAME FACET_NAME INDEX (options)"

      attr_accessor :initial_sleep_delay

      option :dry_run,
        :long => "--dry_run",
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
        cluster_name, facet_name, index = @name_args
        require Chef::Config[:cluster_chef_path]+"/clusters/#{cluster_name}"
       
        cluster = Chef::Config[:clusters][cluster_name]
        facet = cluster.facet(facet_name) if facet_name

        servers = []

        if facet
          facet.resolve!
          
          if index
            servers = [ facet.servers[index] ]
          else
            servers = facet.servers.values
          end
        else
          cluster.resolve!
          servers = cluster.servers
        end
        
        #
        # Display server info
        #
        servers.each do |s|
          p s
        end

      end

    end
  end
end
