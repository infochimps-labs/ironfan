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
class Chef
  class Knife
    class ClusterPry < Knife
      include Ironfan::KnifeCommon
      deps do
        Ironfan::KnifeCommon.load_deps
        require 'pry'
      end

      banner "knife cluster pry                                            - launches a pry shell with the ironfan environment loaded"

      option :cloud,
        :long        => "--[no-]cloud",
        :description => "Look up computers on AWS cloud (default is yes, look up computers; use --no-cloud to skip)",
        :default     => true,
        :boolean     => true

      def _run
        load_ironfan
        die(banner) if @name_args.empty?
        configure_dry_run

        # Load the cluster/facet/slice/whatever
        target = get_slice(* @name_args)
        cluster = target.cluster

        ui.info("")
        ui.info([
            ui.color("You are in a cluster. There is a sign overhead reading '", :magenta),
            ui.color(@name_args.first, :yellow, :bold),
            ui.color("'.\nNext to you a burly man in a greasy apron sharpens his cleaver, \nand a lissom princess performs treacherous origami.", :magenta)
            ].join)
        ui.info(ui.color("It is Pitch Dark. You are likely to be eaten by a grue.", :black, :bold)) if target.select(&:running?).empty?

        # Commands to try:
        #   nn = Chef::Node.load('node-name')
        #   cluster_nodes = cluster.servers.map(&:chef_node)
        #   fog_computers  = cluster.servers.map(&:fog_server)
        #
        binding.pry
      end
    end
  end
end
