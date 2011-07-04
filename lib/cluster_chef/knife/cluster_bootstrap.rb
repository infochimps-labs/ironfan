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
    class ClusterBootstrap < Chef::Knife
      include ClusterChef::KnifeCommon

      deps do
        ClusterChef::KnifeCommon.load_deps
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife cluster bootstrap CLUSTER_NAME FACET_NAME SERVER_FQDN (options)"
      [ :ssh_port, :ssh_password, :identity_file, :no_host_key_verify,
        :prerelease, :bootstrap_version, :template_file,
      ].each do |name|
        option name, Chef::Knife::Bootstrap.options[name]
      end
      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username"
      option :bootstrap_runs_chef_client,
        :long => "--bootstrap-runs-chef-client",
        :description => "If bootstrap is invoked, will do the initial run of chef-client in the bootstrap script"
      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template"
      option :use_sudo,
        :long => "--sudo",
        :description => "Execute the bootstrap via sudo",
        :boolean => true

      def run
        load_cluster_chef
        die(banner) if @name_args.empty?

        cluster_name, facet_name, hostname = @name_args

        #
        # Load the facet
        #
        cluster = ClusterChef.load_cluster(cluster_name)
        facet = Chef::Config[:clusters][cluster_name].facet(facet_name)
        facet.resolve!

        run_bootstrap(facet, hostname)
      end

    end
  end
end
