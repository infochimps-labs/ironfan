#
# Author:: Chris Howe (<howech@infochimps.com>)
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
    class ClusterKill < Knife
      include ClusterChef::KnifeCommon

      deps do
        ClusterChef::KnifeCommon.load_deps
      end

      banner "knife cluster kill CLUSTER_NAME FACET_NAME INDEX (options)"
      option :dry_run,
        :long => "--dry-run",
        :description => "Don't really run, just use mock calls"
      option :undefined,
        :long => "--undefined",
        :descritption => "Kill undefined servers"
      option :no_chef,
        :long => "--no-chef",
        :descrition => "Do not delete chef nodes"
      option :no_fog,
        :long => "--no-fog",
        :description => "Do not delete any fog servers"
      # option :no_defined,
      #   :long => "--no-defined",
      #   :description => "Do not delete any defined nodes (use with --undefined to just clean up)"
      option :yes,
        :long => "--yes",
        :description => "Skip confirmation that you want to delete the cluster."
      option :really,
        :long => "--really",
        :description => "Skip the second confirmation that you REALLY want to delete the cluster."
      option :no,
        :long => "--no",
        :description => "No matter what, do not delete anything."
      option :delete_client,
        :long => "--client",
        :description => "Delete the chef client along with the chef node."
      option :delete_node,
        :long => "--node",
        :description => "Delete the chef client along with the chef node.",
        :default => true
      option :detailed,
        :long => "--detailed",
        :description => "Show detailed info on servers"

      def run
        load_cluster_chef
        die(banner) if @name_args.empty?
        enable_dry_run if config[:dry_run]
        display_style = config[:detailed] ? :detailed : :default

        #
        # Load the cluster/facet/slice/whatever
        #
        target      = ClusterChef.slice(* @name_args)
        chef_nodes  = config[:no_chef] ? [] : target.chef_nodes
        fog_servers = config[:no_fog]  ? [] : target.fog_servers

        target.display(display_style)

        die( "Nothing to delete.", "Exiting.") if chef_nodes.empty? && fog_servers.empty?
        confirm_deletion_of_or_exit(chef_nodes, fog_servers)
        really_confirm_deletion_of_or_exit
        die("Quitting because --no was passed", 1) if config[:no]

        # Execute every last one of em
        target.destroy unless config[:no_fog]
        target.delete_chef(config[:delete_client], config[:delete_node]) unless config[:no_chef]

        # Print out resulting status
        target.display
      end

      def confirm_deletion_of_or_exit chef_nodes, fog_servers
        delete_message = [
          (chef_nodes.empty?  ? nil : "#{chef_nodes.length} chef nodes"),
          (fog_servers.empty? ? nil : "#{fog_servers.length} fog servers") ].compact
        puts
        puts "WARNING!!!!"
        puts
        puts "This command will delete the above #{delete_message.join(" and ")}"
        unless config[:yes]
          puts "Are you absolutely certain that you want to perform this action? (Type 'Yes' to confirm)"
          confirm_or_exit('Yes')
        else
          puts "Bypassing confirmation."
        end
      end

      def really_confirm_deletion_of_or_exit
        unless config[:really]
          puts "..."
          sleep 3
          puts "There is no going back. When these nodes and instances are deleted, they will be gone forever. Are you really sure? (Type 'YES!' to confirm)"
          confirm_or_exit('YES!')
        else
          puts "Bypassing secondary confirmation. I hope you know what you are doing..."
        end
      end

    end
  end
end
