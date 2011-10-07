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
require 'chef/knife/bootstrap'

class Chef
  class Knife
    class ClusterBootstrap < ClusterChef::Script

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
      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use"
      option :use_sudo,
        :long => "--sudo",
        :description => "Execute the bootstrap via sudo",
        :boolean => true
      option :detailed,
        :long => "--detailed",
        :description => "Show detailed info on servers"
      import_banner_and_options(Chef::Knife::Bootstrap,
        :except => [:chef_node_name, :run_list, :ssh_user, :distro, :template_file])
      import_banner_and_options(ClusterChef::Script)

      deps do
        Chef::Knife::Bootstrap.load_deps
        ClusterChef::Script.load_deps
      end

      def perform_execution target
        target.each do |svr|
          run_bootstrap(svr, svr.fog_server.dns_name)
        end
      end

      def confirm_execution target
        unless config[:yes]
          puts "Bootstrapping the node redoes its initial setup -- only do this on an aborted launch."
          puts "Are you absolutely certain that you want to perform this action? (Type 'Yes' to confirm)"
          confirm_or_exit('Yes')
        end
      end

    end
  end
end
