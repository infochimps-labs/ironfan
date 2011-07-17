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

      banner "knife cluster kill CLUSTER_NAME [FACET_NAME [INDEXES]] (options)"
      option :dry_run,
        :long => "--dry-run",
        :description => "Don't really run, just use mock calls",
        :boolean => true
      option :undefined,
        :long => "--undefined",
        :descritption => "Kill undefined servers",
        :boolean => true
      option :no_chef,
        :long => "--no-chef",
        :descrition => "Do not delete chef nodes",
        :boolean => true
      option :no_fog,
        :long => "--no-fog",
        :description => "Do not delete any fog servers",
        :boolean => true
      option :yes,
        :long => "--yes",
        :description => "Skip confirmation that you want to delete the cluster.",
        :boolean => true
      option :really,
        :long => "--really",
        :description => "Skip the second confirmation that you REALLY want to delete the cluster.",
        :boolean => true
      option :no,
        :long => "--no",
        :description => "No matter what, do not delete anything.",
        :boolean => true
      option :delete_client,
        :long => "--client",
        :description => "Delete the chef client along with the chef node.",
        :boolean => true
      option :delete_node,
        :long => "--node",
        :description => "Delete the chef client along with the chef node.",
        :boolean => true,
        :default => true
      option :detailed,
        :long => "--detailed",
        :description => "Show detailed info on servers",
        :boolean => true

      def run
        load_cluster_chef
        die(banner) if @name_args.empty?
        configure_dry_run

        target = get_slice_where(:killable?, *@name_args)

        puts
        Formatador.display_line("[red]Bogus servers detected[reset]: [blue]#{target.bogus_servers.map(&:fullname).inspect}[reset]") unless target.bogus_servers.empty?

        die( "Nothing to kill.", "Exiting.") if target.empty?

        confirm_deletion_of_or_exit(target)
        really_confirm_deletion_of_or_exit
        die("Quitting because --no was passed", 1) if config[:no]

        # Execute every last mf'ing one of em

        unless config[:no_fog]
          puts
          puts "Killing Cloud Machines!!"
          target.select(&:in_cloud?).destroy
          puts
        end

        unless config[:no_chef]
          puts "Killing Chef Nodes!!"
          target.select(&:in_chef? ).delete_chef(config[:delete_client], config[:delete_node])
          puts
        end

        display(target)
      end

      def confirm_deletion_of_or_exit target
        delete_message = [
          ((config[:no_chef] || target.chef_nodes.empty?)  ? nil : "#{target.chef_nodes.length} chef nodes"),
          ((config[:no_fog]  || target.fog_servers.empty?) ? nil : "#{target.fog_servers.length} fog servers") ].compact
        puts
        puts "WARNING!!!!"
        puts
        puts "This command will delete the following #{delete_message.join(" and ")}"
        puts
        display(target)
        puts
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
