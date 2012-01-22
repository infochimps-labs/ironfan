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

require File.expand_path(File.dirname(__FILE__)+"/generic_command.rb")

class Chef
  class Knife
    class ClusterSync < ClusterChef::Script
      import_banner_and_options(ClusterChef::Script)

      option :cloud,
        :long        => "--[no-]cloud",
        :description => "Sync to the cloud (default syncs cloud; use --no-cloud to skip)",
        :default     => true,
        :boolean     => true
      option :chef,
        :long        => "--[no-]chef",
        :description => "Sync to the chef server (default syncs chef; use --no-chef to skip)",
        :default     => true,
        :boolean     => true
      option :sync_all,
        :long        => "--[no-]sync-all",
        :description => "Sync, as best as possible, any defined node (even if it is missing from cloud or chef)",
        :default     => false,
        :boolean     => true


      def relevant?(server)
        if config[:sync_all]
          not server.bogus?
        else
          server.created? && server.in_chef?
        end
      end

      def perform_execution(target)
        if config[:chef]
          sync_to_chef target
        else Chef::Log.debug("Skipping sync to chef") ; end

        if config[:cloud] && target.any?(&:in_cloud?)
          sync_to_cloud target
        else Chef::Log.debug("Skipping sync to cloud") ; end
      end

      def sync_to_chef(target)
        if config[:dry_run]
          ui.info "(can't do a dry-run when syncing to chef -- skipping)"
          return
        end
        ui.info "Syncing to Chef:"
        target.sync_to_chef
      end

      def sync_to_cloud(target)
        ui.info "Syncing to cloud:"
        target.sync_to_cloud
      end

    end
  end
end
