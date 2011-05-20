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

require 'chef/knife'
require 'chef/knife/ssh'

class Chef
  class Knife
    class ClusterSsh < Ssh

      deps do
        require 'net/ssh'
        require 'net/ssh/multi'
        require 'readline'
        require 'chef/search/query'
        require 'chef/mixin/command'
        require 'fog'
      end

      attr_writer :password

      banner 'knife cluster ssh "CLUSTER [FACET [INDEX]]" COMMAND (options)'

      option :concurrency,
        :short => "-C NUM",
        :long => "--concurrency NUM",
        :description => "The number of concurrent connections",
        :default => nil,
        :proc => lambda { |o| o.to_i }

      option :attribute,
        :short => "-a ATTR",
        :long => "--attribute ATTR",
        :description => "The attribute to use for opening the connection - default is fqdn",
        :default => "fqdn"

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


      def configure_session
        cluster_name,facet_name,facet_index = @name_args[0].split(" ")
        cluster = ClusterChef.load_cluster( cluster_name )
        cluster.resolve!
        
        nodes = []
        if facet_name
          facet = cluster.facets[facet_name]
          if facet_index
            server = facet.server_by_index facet_index 
            nodes.push server.chef_node  if server.chef_node
          else
            facet.servers.each do |server|
              nodes.push server.chef_node if server.chef_node
            end
          end
        else
          cluster.servers.each do |server|
            nodes.push server.chef_node if server.chef_node
          end
        end
  
        list = []
        nodes.each do |n|
          i = format_for_display(n)[config[:attribute]]
          list.push(i) unless i.nil?
        end

        (ui.fatal("No nodes returned from search!"); exit 10) if list.length == 0
        session_from_list(list)
      end

      def cssh
        exec "cssh "+session.servers_for.map {|server| server.user ? "#{server.user}@#{server.host}" : server.host}.join(" ")
      end


      def run
        # TODO: this is a hack - remove when ClusterChef is deployed as a gem
        $: << Chef::Config[:cluster_chef_path]+'/lib'

        # TODO: this is a hack - should be moved to some kind of configuration
        #       controllable by the user, perhaps in a knife.rb file. Needs to
        #       be fixed as a part of separating cluster configuration from
        #       ClusterChef gem.  However, it is currently required to get 
        #       ClusterChef.load_cluster to work right.
        $: << Chef::Config[:cluster_chef_path]

        require 'cluster_chef'

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

