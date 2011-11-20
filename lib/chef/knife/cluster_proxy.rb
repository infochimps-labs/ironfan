#
# Author:: Philip (flip) Kromer (flip@infochimps.com)
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
require File.expand_path(File.dirname(__FILE__)+"/cluster_ssh.rb")
require File.expand_path(File.dirname(__FILE__)+"/generic_command.rb")

class Chef
  class Knife
    #
    # Runs the ssh command to open a SOCKS proxy to the given host, and writes a
    # PAC (automatic proxy config) file to
    # /tmp/cluster_chef_proxy-YOURNAME.pac. Only the first host is used, even if
    # multiple match.
    #
    # Why not use Net::Ssh directly? The SOCKS proxy support was pretty
    # bad. Though ugly, exec'ing the command works.
    #
    class ClusterProxy < ClusterChef::Script

      import_banner_and_options(Chef::Knife::ClusterSsh, :except => [:concurrency, ])
      banner 'knife cluster proxy "CLUSTER [FACET [INDEXES]]" (options) - Runs the ssh command to open a SOCKS proxy to the given host, and writes a PAC (automatic proxy config) file to /tmp/cluster_chef_proxy-YOURNAME.pac. Only the first host is used, even if multiple match.'

      option :background,
        :long        => "--[no-]background",
        :description => "Requests ssh to go to background after setting up the proxy",
        :boolean     => true,
        :default     => true

      option :socks_port,
        :long        => '--socks-port',
        :short       => '-D',
        :description => 'Port to listen on for SOCKS5 proxy',
        :default     => '6666'
      
      def slice_criterion
        :sshable?
      end
      
      def perform_execution(target)
        svr = target.first
        cmd = command_for_target(svr)

        dump_proxy_pac
        exec(*cmd)
      end

      def command_for_target(svr) 
        config[:attribute]     ||= Chef::Config[:knife][:ssh_address_attribute] || "fqdn"
        config[:ssh_user]      ||= Chef::Config[:knife][:ssh_user]
        config[:identity_file] ||= svr.cloud.ssh_identity_file

        if (svr.cloud.public_ip)             then address = svr.cloud.public_ip ; end
        if (not address) && (svr.chef_node)  then address = format_for_display( svr.chef_node )[config[:attribute]] ; end
        if (not address) && (svr.fog_server) then address = svr.fog_server.public_ip_address ; end

        cmd  = [ 'ssh', '-N' ]
        cmd += [ '-D', config[:socks_port].to_s  ]
        cmd += [ '-i', config[:identity_file]    ] if config[:identity_file].present?
        cmd += [ '-p', config[:port].to_s        ] if config[:port].present?
        cmd << '-f'                                if config[:background]
        cmd << "-#{'v' * config[:verbosity]}"      if (config[:verbosity] > 0)
        cmd += %w[ -o StrictHostKeyChecking=no   ] if config[:no_host_key_verify]
        cmd += %w[ -o ConnectTimeout=10 -o ServerAliveInterval=60 -o ControlPath=none ]
        cmd << (config[:ssh_user] ? "#{config[:ssh_user]}@#{address}" : address)

        Chef::Log.debug("Cluster proxy config:  #{config.inspect}")
        Chef::Log.debug("Cluster proxy command: #{cmd.inspect}")
        ui.info(["SOCKS Proxy on",
            "local port", ui.color(config[:socks_port], :cyan),
            "for",        ui.color(svr.name,            :cyan),
            "(#{address})"
          ].join(" "))
        cmd
     end

      #
      # Write a .pac (automatic proxy configuration) file
      # to /etc/cluster_chef_proxy-YOURNAME.pac
      #
      def dump_proxy_pac
        pac_filename = File.expand_path(File.join('/tmp', "cluster_chef_proxy-#{ENV['USER']}.pac"))
        ui.info("point your browser at PAC (automatic proxy config file) #{pac_filename}")
        File.open(pac_filename, 'w') do |f|
          f.print %Q{function FindProxyForURL(url, host) {
  if ((shExpMatch(host, "*ec2*.amazonaws.com"      )) ||
      (shExpMatch(host, "*ec2.internal*"           )) ||
      (shExpMatch(host, "*compute-*.amazonaws.com" )) ||
      (shExpMatch(host, "*compute-*.internal*"     )) ||
      (shExpMatch(host, "*domu*.internal*"         )) ||
      (shExpMatch(host, "10.*"                     )) 
      ) {
    return "SOCKS5 localhost:#{config[:socks_port]}";
  }
  return "DIRECT";
}
         }
        end
      end

    end
  end
end


#
# Does not work. sad.
#

# deps do
#   require 'net/ssh/socks'
# end
#
# def session_from_list(addresses)
#   item = addresses.first
#   
#   hostspec = config[:ssh_user] ? "#{config[:ssh_user]}@#{item}" : item
#   session_opts = {}
#   session_opts[:keys]     = File.expand_path(config[:identity_file]) if config[:identity_file]
#   session_opts[:password] = config[:ssh_password]                    if config[:ssh_password]
#   # session_opts[:logger]   = Chef::Log.logger                         if Chef::Log.level == :debug
#   session_opts[:port]     = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
# 
#   if config[:no_host_key_verify]
#     session_opts[:paranoid]              = false
#     session_opts[:user_known_hosts_file] = "/dev/null"
#   end
# 
#   session_opts[:username] = 'flip' # config[:ssh_user] if config[:ssh_user]
#   session_opts.delete :keys
#   Chef::Log.info( [addresses, hostspec, session_opts, @action_nodes ].inspect )
#   
#   @session = Net::SSH.start(item, session_opts)
#   # do |ssh|
#   #   ssh.forward.socks(6666)
#   #   ssh.loop { true }
#   # end
# end
