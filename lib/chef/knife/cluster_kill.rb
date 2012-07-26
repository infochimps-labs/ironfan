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

require File.expand_path('ironfan_script', File.dirname(File.realdirpath(__FILE__)))

class Chef
  class Knife
    class ClusterKill < Ironfan::Script
      import_banner_and_options(Ironfan::Script)

      option :kill_bogus,
        :long        => "--kill-bogus",
        :description => "Kill bogus servers (ones that exist, but are not defined in the clusters file)",
        :boolean     => true,
        :default     => false
      option :cloud,
        :long        => '--[no-]cloud',
        :description => "Kill machines from cloud (default is yes, terminate machines; use --no-cloud to skip)",
        :boolean     => true,
        :default     => true
      option :chef,
        :long        => "--[no-]chef",
        :description => "Delete the chef node and client (default is yes, delete chef objects; use --no-chef to skip)",
        :boolean     => true,
        :default     => true

      def relevant?(server)
        server.killable?
      end

      # Execute every last mf'ing one of em
      def perform_execution(target)
        if config[:cloud]
          section("Killing Cloud Machines")
          broker.kill! target, :providers => :iaas
        end

        if config[:chef]
          section("Killing Chef")
          broker.kill! target, :providers => :chef
        end
      end

      def display(target, *args, &block)
        super

        permanent = target.select(&:permanent?)
        ui.info Formatador.display_line("servers with [red]'permanent=true'[reset] ignored: [blue]#{permanent.map(&:name).inspect}[reset]. (To kill, change 'permanent' to false, run knife cluster sync, and re-try)") unless permanent.empty?

        bogus = target.select(&:bogus?)
        ui.info Formatador.display_line("[red]Bogus servers detected[reset]: [blue]#{bogus.map(&:name).inspect}[reset]") unless bogus.empty?
      end

      def confirm_execution(target)
        nodes           = target.map(&:node).compact
        instances       = target.map(&:instance).compact
        delete_message = [
          (((!config[:chef])   || nodes.empty?)  ? nil : "#{nodes.length} chef nodes"),
          (((!config[:cloud])  || instances.empty?) ? nil : "#{instances.length} fog servers") ].compact.join(" and ")
        confirm_or_exit("Are you absolutely certain that you want to delete #{delete_message}? (Type 'Yes' to confirm) ", 'Yes')
      end

    end
  end
end
