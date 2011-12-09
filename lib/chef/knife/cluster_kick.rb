#
# Author:: Ash Berlin (ash_github@firemirror.om) and Philip (flip) Kromer (flip@infochimps.com)
# Copyright:: Copyright (c) 2011 DigiResults Ltd. and Infochimps, Inc.
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

class Chef
  class Knife
    #
    # Based on https://gist.github.com/1325982 by Ash Berlin
    #
    #     "Since chef v0.10 you can send USR1 to the chef-client process and it
    #     will wake up and do a run. But the usual case when I want to do a run
    #     is cos I'm either testing a cookbook change or I want to deploy now. I
    #     could just run sudo chef-client but then that will only log to std
    #     out.  Just run this script, it will send chef-client a USR1 signal and
    #     then tail the log file (but nicely so that you'll get your terminal
    #     back when the run completes)."
    #
    class ClusterKick < Chef::Knife::ClusterSsh

      import_banner_and_options(Chef::Knife::ClusterSsh)
      banner 'knife cluster kick "CLUSTER [FACET [INDEXES]]" (options) - start a run of chef-client on each server, tailing the logs and exiting when the run completes.'

      option :pid_file,
        :long        => "--pid_file",
        :description => "Where to find the pid file. Typically /var/run/chef/client.pid (init.d) or /etc/sv/chef-client/supervise/pid (runit)",
        :default     => "/etc/sv/chef-client/supervise/pid"

      unless defined?(KICKSTART_SCRIPT)
        KICKSTART_SCRIPT = <<EOF
#!/bin/bash
set -e
<%= ((config[:verbosity].to_i > 1) ? "set -v" : "") %>

pid_file="<%= config[:pid_file] %>"
log_file=/var/log/chef/client.log

declare tail_pid

on_exit() {
  rm -f $pipe
  [ -n "$tail_pid" ] && kill $tail_pid
}

trap "on_exit" EXIT ERR

pipe=/tmp/pipe-$$
mkfifo $pipe

tail -fn0 "$log_file" > $pipe &

tail_pid=$!

sudo true
pid="$(sudo cat $pid_file)"
sudo kill -USR1 "$pid"
sed -r "/(ERROR: Sleeping for [0-9]+ seconds before trying again|INFO: Report handlers complete)\$/{q}" $pipe
EOF
      end

      def run
        @name_args = [ @name_args.join(' ') ]
        script = Erubis::Eruby.new(KICKSTART_SCRIPT).result(:config => config)
        @name_args[1] = script
        super
      end

    end
  end
end
