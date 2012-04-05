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

require File.expand_path('ironfan_script', File.dirname(File.realdirpath(__FILE__)))
require 'chef/knife/bootstrap'

class Chef
  class Knife
    class ClusterBootstrap < Ironfan::Script

      option :ssh_user,
        :long        => "--ssh-user USERNAME",
        :short       => "-x USERNAME",
        :description => "The ssh username"
      option :bootstrap_runs_chef_client,
        :long        => "--[no-]bootstrap-runs-chef-client",
        :description => "If bootstrap is invoked, the bootstrap script causes an initial run of chef-client (default true).",
        :boolean     => true,
        :default     => true
      option :distro,
        :long        => "--distro DISTRO",
        :short       => "-d DISTRO",
        :description => "Bootstrap a distro using a template"
      option :template_file,
        :long        => "--template-file TEMPLATE",
        :description => "Full path to location of template to use"
      option :use_sudo,
        :long        => "--sudo",
        :description => "Execute the bootstrap via sudo",
        :boolean     => true
      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      import_banner_and_options(Chef::Knife::Bootstrap,
        :except => [:chef_node_name, :run_list, :ssh_user, :distro, :template_file, :no_host_key_verify, :host_key_verify])
      import_banner_and_options(Ironfan::Script)

      deps do
        Chef::Knife::Bootstrap.load_deps
        Ironfan::Script.load_deps
      end

      def perform_execution(target)
        # Execute across all servers in parallel
        threads = target.servers.map{ |server| Thread.new(server) { |svr| run_bootstrap(svr, svr.fog_server.ipaddress) } }
        # Wait for the threads to finish and return the array of thread's exit value
        threads.map{ |t| t.join.value }
      end

      def confirm_execution(target)
        ui.info "Bootstrapping the node redoes its initial setup -- only do this on an aborted launch."
        confirm_or_exit("Are you absolutely certain that you want to perform this action? (Type 'Yes' to confirm) ", 'Yes')
      end

    end
  end
end
