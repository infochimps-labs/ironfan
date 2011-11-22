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

      def configure_session
        predicate = @name_args[0].split(/[\s\-]+/,3).map(&:strip)

        target = get_slice(*predicate).select(&:sshable?)

        display(target) if config[:verbose]

        config[:attribute]     ||= Chef::Config[:knife][:ssh_address_attribute] || "fqdn"
        config[:ssh_user]      ||= Chef::Config[:knife][:ssh_user]
        config[:identity_file] ||= target.ssh_identity_file

        @action_nodes = target.chef_nodes
        addresses = target.servers.map do |svr|
          if (svr.cloud.public_ip)            then address = svr.cloud.public_ip ; end
          if (not address) && (svr.fog_server) then address = svr.fog_server.public_ip_address ; end
          if (not address) && (svr.chef_node)  then address = format_for_display( svr.chef_node )[config[:attribute]] ; end
          address
        end.compact

        (ui.fatal("No nodes returned from search!"); exit 10) if addresses.nil? || addresses.length == 0

        session_from_list(addresses)
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
        when "interactive"  then interactive
        when "screen"       then screen
        when "tmux"         then tmux
        when "macterm"      then macterm
        when "cssh"         then cssh
        else
          ssh_command(@name_args[1..-1].join(" "))
        end

        session.close
      end

    end
  end
end
