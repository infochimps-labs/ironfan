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

    #
    # Vagrant support is VERY rough. It will
    #
    # * change the ui/commandline args, at the worst possible moment for you to adapt
    # * show you info that is inaccurate, even beyond the obvious fact that it reports AWS properties.
    # * translate your documents into swahili, make your TV record Gigli -- [tracker issue here](http://bit.ly/vrsalert)
    #
    # Vagrant has a really strong narcissistic streak, even more so than chef
    # and ironfan already do.  I don't want to fight (it's probably that way for
    # good reasons), so the following oddball procedure may persist until it a)
    # stops working well or b) someone recommends a better approach.
    #
    # when you run `knife cluster vm command cluster-[facet-[indexes]]` we:
    #
    # * identify all servers defined on that cluster
    # * find (or make) the directory config.vagrant_path
    #   - if unset, will use `{homebase}/vagrants/{cluster_name}`
    # * copy a special-purpose vagrantfile into that directory
    #   - it is called vagrantfile, but won't work in a standalone way.
    #
    #
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

      banner "knife cluster vm COMMAND CLUSTER-[FACET-[INDEXES]] (options)"

      option :cloud,
        :long        => "--cloud PROVIDER",
        :short       => "-p",
        :description => "cloud provider to target, or 'false' to skip cloud-targeted steps. (default false)",
        :default     => false,
        :boolean     => false

      def run
        # The subnet for thi
        Chef::Config.host_network_blk   ||= '33.33.33'
        # Location that cookbooks, roles, etc will be mounted on vm
        # set to false to skip
        Chef::Config.homebase_on_vm_dir "/homebase" if Chef::Config.homebase_on_vm_dir.nil?
        # yuck. necessary until cloud agnosticism shows up
        Chef::Config[:cloud] = config[:cloud] = false
        # TODO: make this customizable
        Chef::Config[:vagrant_path] = File.expand_path("vagrants", Chef::Config.homebase)

        # standard ironfan knife preamble
        load_ironfan
        die("Missing command or slice:\n#{banner}") if @name_args.length < 2
        die("Too many args:\n#{banner}")            if @name_args.length > 2
        configure_dry_run
        ui.warn "Vagrant support is VERY rough: the ui will change, displays are inaccurate, may translate your documents into swahili"

        #
        # Load the servers. Note carefully: this is subtly different from all
        # the other `knife cluster` commands. Vagrant provides idempotency, but
        # we want the vagrant file to be invariant to the particular servers
        # you're asking it to diddle.
        #
        # So we configure VMs for all servers in the cluster, but only issue the
        # cli command against the ones given by the server slice.
        #
        vagrant_command, slice_string = @name_args
        target      = get_slice(slice_string)
        all_servers = target.cluster.servers
        display(target)

        # Pre-populate information in chef
        section("Sync'ing to chef and cloud")
        target.sync_to_chef

        # FIXME: I read somewhere that global variables are a smell for something
        $ironfan_target = all_servers

        #
        # Prepare vagrant
        #
        section("Configuring vagrant", :green)

        cluster_vagrant_dir  = File.expand_path(target.cluster.name.to_s, Chef::Config.vagrant_path)
        skeleton_vagrantfile = File.expand_path('vagrant/skeleton_vagrantfile.rb', IRONFAN_DIR)

        # using ':vagrantfile_name => skeleton_vagrantfile' doesn't seem to work
        # in vagrant - the VM comes out incompletely configured in a way I don't
        # totally understand. Plus it wants its own directory anyhow. So, make a
        # directory to hold vagrantfiles and push the skeleton in there
        FileUtils.mkdir_p cluster_vagrant_dir
        FileUtils.cp      skeleton_vagrantfile, File.join(cluster_vagrant_dir, 'vagrantfile')

        log_level = [0, (3 - config.verbosity)].max
        env = Vagrant::IronfanEnvironment.new(
          :ui_class    => Vagrant::UI::Colored,
          :cwd         => cluster_vagrant_dir,
          :log_level   => log_level,
          )

        #
        # Run command
        #
        section("issuing command 'vagrant #{vagrant_command}'", :green)

        env.cli(vagrant_command, * target.servers.map(&:fullname))
      end

      def display(target)
        super(target.cluster.servers,
          ["Name", "InstanceID", "State", "Flavor", "Image", "AZ", "Public IP", "Private IP", "Created At", 'Volumes', 'Elastic IP']) do |svr|
          { 'targeted?' => (target.include?(svr) ? "[blue]true[reset]" : '-' ), }
        end
      end

    end
  end
end
