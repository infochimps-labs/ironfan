#
# Author:: Chris Howe (<chris@infochimps.com>)
# Copyright:: Copyright (c) 2011 Infochimps, Inc.
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
require 'chef/knife/ssh'

class Chef
  class Knife
    class ClusterSsh < Chef::Knife::Ssh
      include ClusterChef::KnifeCommon

      deps do
        Chef::Knife::Ssh.load_deps
        ClusterChef::KnifeCommon.load_deps
      end

      banner 'knife cluster ssh "CLUSTER [FACET [INDEXES]]" COMMAND (options)'
      Chef::Knife::Ssh.options.each do |name, hsh|
        next if name == :attribute
        option name, hsh
      end

      option :attribute,
        :short => "-a ATTR",
        :long => "--attribute ATTR",
        :description => "The attribute to use for opening the connection - default is fqdn (ec2 users may prefer cloud.public_hostname)"

      option :detailed,
        :long => "--detailed",
        :description => "Show detailed info on servers. (Only shows summary with --detailed or --verbose)"

      def configure_session
        predicate = @name_args[0].split(/\s+/).map(&:strip)

        target = get_slice(*predicate).select(&:sshable?)

        display(target) if config[:detailed] || config[:verbose]

        config[:attribute]     ||= Chef::Config[:knife][:ssh_address_attribute] || "fqdn"
        config[:ssh_user]      ||= Chef::Config[:knife][:ssh_user]
        config[:identity_file] ||= target.ssh_identity_file

        Chef::Log.debug JSON.pretty_generate(config)

        @action_nodes = target.chef_nodes
        list = target.servers.map do |svr|
          if svr.chef_node
            format_for_display( svr.chef_node )[config[:attribute]]
          elsif svr.fog_server
            svr.fog_server.public_ip_address
          else
            nil
          end
        end.compact

        (ui.fatal("No nodes returned from search!"); exit 10) if list.nil? || list.length == 0

        session_from_list(list)
      end

      def cssh
        exec "cssh "+session.servers_for.map {|server| server.user ? "#{server.user}@#{server.host}" : server.host}.join(" ")
      end

      def run
        load_cluster_chef
        die(banner) if @name_args.empty?
        extend Chef::Mixin::Command

        @longest = 0

        configure_session

        case @name_args[1]
        when "interactive"
          interactive
        when "screen"
          screen
        when "tmux"
          tmux
        when "macterm"
          macterm
        when "cssh"
          cssh
        else
          ssh_command(@name_args[1..-1].join(" "))
        end

        session.close
      end

    end
  end
end

