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

      banner "knife cluster bootstrap CLUSTER_NAME FACET_NAME SERVER_FQDN (options)"

      attr_accessor :initial_sleep_delay

      option :bootstrap,
        :long => "--bootstrap",
        :description => "Also bootstrap the launched node"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

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
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'
        $: << Chef::Config[:cluster_chef_path]+'/lib'
        require 'cluster_chef'
        $stdout.sync = true

        #
        # Load the facet
        #
        cluster_name, facet_name, server_name = @name_args
        raise "Bootstrap a node with: knife cluster bootstrap CLUSTER_NAME FACET_NAME SERVER_FQDN (options)" if facet_name.blank?
        require File.expand_path(Chef::Config[:cluster_chef_path]+"/clusters/#{cluster_name}")
        facet = Chef::Config[:clusters][cluster_name].facet(facet_name)
        facet.resolve!

        config[:ssh_user]       = facet.cloud.ssh_user
        config[:identity_file]  = facet.cloud.ssh_identity_file
        config[:chef_node_name] = facet.chef_node_name
        config[:distro]         = facet.cloud.bootstrap_distro
        config[:run_list]       = facet.run_list

        #
        # Bootstrap 
        #
        bootstrap_for_node(server_name).run
      end

      def bootstrap_for_node(server_name)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args               = [server_name]
        bootstrap.config[:run_list]       = config[:run_list]
        bootstrap.config[:ssh_user]       = config[:ssh_user]
        bootstrap.config[:identity_file]  = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name]
        bootstrap.config[:prerelease]     = config[:prerelease]
        bootstrap.config[:distro]         = config[:distro]
        bootstrap.config[:use_sudo]       = true
        bootstrap.config[:template_file]  = config[:template_file]
        bootstrap
      end

    end
  end
end
