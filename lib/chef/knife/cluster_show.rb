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
        ClusterChef::KnifeCommon.load_deps
      end

      banner "knife cluster show CLUSTER_NAME [FACET_NAME [INDEXES]] (options)"

      def run
        load_cluster_chef
        die(banner) if @name_args.empty?
        configure_dry_run

        # Load the cluster/facet/slice/whatever
        target = get_slice(* @name_args)

        #
        # Dump entire contents of objects if -VV flag given
        #
        if config[:verbosity] >= 2
          target.each do |svr|
            Chef::Log.debug( "Server #{svr.name}: #{JSON.pretty_generate(svr.to_hash)}" )
            Chef::Log.debug( "- cloud: #{JSON.pretty_generate(svr.cloud.to_hash)}" )
            Chef::Log.debug( "- fog:   #{JSON.pretty_generate(svr.fog_launch_description)}" )
          end
        end

        # Display same
        display(target)

      end
    end
  end
end
