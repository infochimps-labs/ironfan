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

require 'socket'
require 'chef/knife'
require 'json'

class Chef
  class Knife
    class ClusterBootstrap < Knife
      deps do
        Chef::Knife::Bootstrap.load_deps
      end

      deps do
        require 'chef/knife/core/bootstrap_context'
        require 'chef/json_compat'
        require 'tempfile'
        require 'highline'
        require 'net/ssh'
        require 'net/ssh/multi'
        require 'fog'
        require 'readline'
        Chef::Knife::Ssh.load_deps
      end rescue nil

      banner "knife cluster bootstrap CLUSTER_NAME FACET_NAME SERVER_FQDN (options)"

      attr_accessor :initial_sleep_delay

      option :bootstrap,
        :long => "--bootstrap",
        :description => "Also bootstrap the launched node"

      option :bootstrap_runs_chef_client,
        :long => "--bootstrap-runs-chef-client",
        :description => "If bootstrap is invoked, will do the initial run of chef-client in the bootstrap script"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :no_host_key_verify,
        :long => "--no-host-key-verify",
        :description => "Disable host key verification",
        :boolean => true,
        :default => false

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems when bootstrapping"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use when bootstrapping",
        :default => false

      def h
        @highline ||= HighLine.new
      end

      def run
        $: << Chef::Config[:cluster_chef_path]+'/lib'
        require 'cluster_chef'
        $stdout.sync = true

        #
        # Load the facet
        #
        cluster_name, facet_name, server_name = @name_args
        raise "Bootstrap a node with: knife cluster bootstrap CLUSTER_NAME FACET_NAME SERVER_FQDN (options)" if facet_name.nil? #.blank?

        cluster = ClusterChef.load_cluster(cluster_name)
        facet = Chef::Config[:clusters][cluster_name].facet(facet_name)
        facet.resolve!

        #
        # Bootstrap
        #
        bootstrap_for_node(facet, server_name).run
      end

      def bootstrap_for_node(node, server_name)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args               = [server_name]
        bootstrap.config[:run_list]       = config[:run_list]       || node.run_list
        bootstrap.config[:ssh_user]       = config[:ssh_user]       || node.cloud.ssh_user
        bootstrap.config[:identity_file]  = config[:identity_file]  || node.cloud.ssh_identity_file
        bootstrap.config[:distro]         = config[:distro]         || node.cloud.bootstrap_distro
        bootstrap.config[:chef_node_name] = config[:chef_node_name]
        bootstrap.config[:prerelease]     = config[:prerelease]
        bootstrap.config[:use_sudo]       = true
        bootstrap.config[:template_file]  = config[:template_file]
        bootstrap.config[:bootstrap_runs_chef_client] = config[:bootstrap_runs_chef_client]
        Chef::Log.debug bootstrap.config.inspect
        bootstrap
      end

    end
  end
end
