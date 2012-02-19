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

require File.expand_path('ironfan_knife_common', File.dirname(File.realdirpath(__FILE__)))

class Chef
  class Knife
    class ClusterVm < Knife
      include Ironfan::KnifeCommon

      deps do
        Ironfan::KnifeCommon.load_deps
        require 'vagrant'
      end

      banner "knife cluster vm CLUSTER_NAME [FACET_NAME [INDEXES]] (options)"

      option :cloud,
        :long        => "--[no-]cloud",
        :description => "Look up machines on AWS cloud (default is no, don't look up machines; use --cloud to force)",
        :default     => false,
        :boolean     => true

      def run
        load_ironfan
        die(banner) if @name_args.empty?
        configure_dry_run


        env = Vagrant::Environment.new(:cwd => "/Users/flip/ics/sysadmin/ironfan-ci/vagrants/cocina-sandbox")

        p [ env ]

        # #
        # # Load the facet
        # #
        # full_target = get_slice(*@name_args)
        # display(full_target)
        # # target = full_target.select(&:launchable?)
        # target = full_target
        #
        # # warn_or_die_on_bogus_servers(full_target) unless full_target.bogus_servers.empty?
        # die("", "#{ui.color("All servers are running -- not launching any.",:blue)}", "", 1) if target.empty?
        #
        # # Pre-populate information in chef
        # section("Sync'ing to chef and cloud")
        # # target.sync_to_cloud
        # target.sync_to_chef
        #
        # # Launch servers
        # section("Launching machines", :green)
        # # target.create_vms
        #
        # ui.info("")
        # display(target)

      end

    end
  end
end
