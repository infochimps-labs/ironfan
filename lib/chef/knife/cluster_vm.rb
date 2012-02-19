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
    class ClusterVm < Knife
      IRONFAN_DIR = File.dirname(File.realdirpath(__FILE__))
      require File.expand_path('ironfan_knife_common', IRONFAN_DIR)
      include Ironfan::KnifeCommon

      deps do
        Ironfan::KnifeCommon.load_deps
        require 'vagrant'
        require File.expand_path('vagrant/ironfan_environment',  IRONFAN_DIR)
        require File.expand_path('vagrant/ironfan_provisioners', IRONFAN_DIR)
      end

      banner "knife cluster vm CLUSTER_NAME [FACET_NAME [INDEXES]] (options)"

      option :cloud,
        :long        => "--[no-]cloud",
        :description => "Look up machines on AWS cloud (default is no, don't look up machines; use --cloud to force)",
        :default     => false,
        :boolean     => true

      option :vagrant,
        :long        => "--vagrant CMD",
        :description => "Command to pass to vagrant",
        :default     => "status",
        :boolean     => false

      def run
        load_ironfan
        die(banner) if @name_args.empty?
        configure_dry_run

        p [@name_args]

        #
        # Load the facet
        #
        full_target = get_slice(*@name_args)
        display(full_target)

        # target = full_target.select(&:launchable?)
        # # warn_or_die_on_bogus_servers(full_target) unless full_target.bogus_servers.empty?
        # die("", "#{ui.color("All servers are running -- not launching any.",:blue)}", "", 1) if target.empty?
        target = full_target # FIXME: using all servers

        # # Pre-populate information in chef
        # section("Sync'ing to chef and cloud")
        # # target.sync_to_cloud
        # target.sync_to_chef

        $ironfan_target = target

        # Launch servers
        section("Launching machines", :green)
        # target.create_vms

        # cluster_name = target.cluster.name
        cluster_name = 'sandbox'

        #cluster_vagrant_dir  = File.expand_path("vagrants/#{cluster_name}", Chef::Config.homebase)
        cluster_vagrant_dir  = File.expand_path("../ironfan-ci/vagrants/cocina-sandbox", Chef::Config.homebase)
        skeleton_vagrantfile = File.expand_path('vagrant/skeleton_vagrantfile.rb', IRONFAN_DIR)

        FileUtils.mkdir_p cluster_vagrant_dir

        log_level = [0, (3 - config.verbosity)].max
        env = Vagrant::IronfanEnvironment.new(
          :ui_class    => Vagrant::UI::Colored,
          :cwd         => cluster_vagrant_dir,
          :log_level   => log_level,
          # :vagrantfile_name => skeleton_vagrantfile
          )

        # p [ Chef::Config.homebase ]
        # p [ env.vms ]
        env.cli(config[:vagrant])

        # ui.info("")
        # display(target)
      end

    end
  end
end
