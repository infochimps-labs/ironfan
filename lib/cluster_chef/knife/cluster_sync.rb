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
require File.expand_path(File.dirname(__FILE__)+"/generic_command.rb")

class Chef
  class Knife
    class ClusterSync < ClusterChef::Script
      import_banner_and_options(ClusterChef::Script)

      option :cloud,
        :long => "--cloud",
        :description => "Sync to the cloud",
        :default => true
      option :chef,
        :long => "--chef",
        :description => "Sync to the chef server",
        :default => true
      
      def slice_criterion
        :stoppable?
      end

      def perform_execution target
        sync_to_cloud target
        puts
        display(target)
        puts
        sync_to_chef target
      end

      def sync_to_chef target
        if config[:dry_run]
          puts "(can't do a dry-run when syncing to chef -- skipping)"
          return
        end
        puts "Syncing to Chef:"
        target.sync_to_chef
      end
      
      def sync_to_cloud target
        puts "Syncing to cloud:"
        target.sync_to_cloud
      end

      def display(target, *args)
        super(target, :expanded)
      end
      
    end
  end
end
