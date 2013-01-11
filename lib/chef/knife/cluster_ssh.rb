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

require File.expand_path('ironfan_knife_common', File.dirname(File.realdirpath(__FILE__)))
require 'chef/knife/ssh'

class Chef
  class Knife
    class ClusterSsh < Chef::Knife::Ssh
      include Ironfan::KnifeCommon

      deps do
        Chef::Knife::Ssh.load_deps
        Ironfan::KnifeCommon.load_deps
      end

      banner 'knife cluster ssh         CLUSTER[-FACET[-INDEXES]] COMMAND (options)'
      Chef::Knife::Ssh.options.each do |name, hsh|
        next if name == :attribute
        option name, hsh
      end

      option :attribute,
        :short => "-a ATTR",
        :long => "--attribute ATTR",
        :description => "The attribute to use for opening the connection - default is fqdn (ec2 users may prefer cloud.public_hostname)"

      def configure_session
        target = get_slice(@name_args[0]).select(&:running?)

        display(target) if config[:verbose] || config[:display_target]

        config[:attribute]     ||= Chef::Config[:knife][:ssh_address_attribute] || "fqdn"
        config[:ssh_user]      ||= Chef::Config[:knife][:ssh_user]
#        config[:identity_file] ||= target.ssh_identity_file

#         @action_nodes = target.chef_nodes
        #action_nodes needs to be an Array or chef will fail with nil:NilClass Exception
        @action_nodes = []
        target = target.select {|t| not t.bogus? }
        #For some reason the ssh_identity_file config above was removed from target.
        config[:identity_file] ||= target.map {|c| c.keypair.key_filename }.compact.first
        addresses = target.map {|c| c.machine.vpc_id.nil? ? c.machine.public_hostname : c.machine.public_ip_address }.compact

        (ui.fatal("No nodes returned from search!"); exit 10) if addresses.nil? || addresses.length == 0

        session_from_list(addresses)
      end

      #
      # Override the one in Chef::Knife::Ssh to allow an err flag (prints in red
      # if non-null)
      #
      def print_data(host, data, err=nil)
        if data =~ /\n/
          data.split(/\n/).each { |d| print_data(host, d, err) }
        else
          padding = @longest - host.length
          str = ui.color(host, :cyan) + (" " * (padding + 1)) + (err ? ui.color(data, :red) : data)
          ui.msg(str)
        end
      end

      #
      # Override the one in Chef::Knife::Ssh to give a big red warning if the
      # process executes with badness
      #
      def ssh_command(command, subsession=nil)
        subsession ||= session
        command = fixup_sudo(command)
        #
        subsession.open_channel do |ch|
          ch.request_pty
          ch.exec command do |ch, success|
            raise ArgumentError, "Cannot execute #{command}" unless success
            # note: you can't do the stderr calback because requesting a pty
            # squashes stderr and stdout together
            ch.on_data do |ichannel, data|
              print_data(ichannel[:host], data)
              if data =~ /^knife sudo password: /
                ichannel.send_data("#{get_password}\n")
              end
            end
            ch.on_request "exit-status" do |ichannel, data|
              exit_status = data.read_long
              if exit_status != 0
                command_snippet = (command.length < 70) ? command : (command[0..45] + ' ... ' + command[-19..-1])
                has_problem ->{ print_data(ichannel[:host], "'#{command_snippet.gsub(/[\r\n]+/, "; ")}' terminated with error status #{exit_status}", :err) }
              end
            end
          end
        end
        session.loop
      end

      def cssh
        exec "cssh "+session.servers_for.map{|server| server.user ? "#{server.user}@#{server.host}" : server.host}.join(" ")
      end

      def run
        load_ironfan
        die(banner) if @name_args.empty?
        extend Chef::Mixin::Command

        @longest = 0
        configure_session

        case @name_args[1]
        when "screen",nil   then screen
        when "interactive"  then interactive
        when "tmux"         then tmux
        when "macterm"      then macterm
        when "cssh"         then cssh
        else
          ssh_command(@name_args[1..-1].join(" "))
        end

        session.close
        exit_if_unhealthy!
      end

    end
  end
end
