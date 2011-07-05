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
    class ClusterStop < Knife
      include ClusterChef::KnifeCommon

      deps do
        ClusterChef::KnifeCommon.load_deps
      end

      banner "knife cluster stop CLUSTER_NAME [FACET_NAME [INDEXES]] (options)"
      option :dry_run,
        :long => "--dry-run",
        :description => "Don't really run, just use mock calls"
      option :yes,
        :long => "--yes",
        :description => "Skip confirmation that you want to stop the cluster."
      option :detailed,
        :long => "--detailed",
        :description => "Show detailed info on servers"

      def run
        load_cluster_chef
        die(banner) if @name_args.empty?
        enable_dry_run if config[:dry_run]

        target = get_slice_where(:stoppable?, *@name_args)

        die("No nodes to stop, exiting", 1) if target.empty?

        unless config[:yes]
          puts "This action will stop the following nodes:"
          target.display(display_style)
          puts "Unless these nodes are backed by EBS volumes, this will result in loss of all"
          puts "data not saved elsewhere. Even if they are EBS backed, there may still be some data loss."
          puts "Are you absolutely certain that you want to perform this action? (Type 'Yes' to confirm)"
          confirm_or_exit('Yes')
        end

        puts
        puts "Stopping!!"
        target.stop
        puts
        target.display(display_style)
      end
    end
  end
end
