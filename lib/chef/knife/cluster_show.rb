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

require File.expand_path('ironfan_knife_common', File.dirname(File.realdirpath(__FILE__)))

class Chef
  class Knife
    class ClusterShow < Knife
      include Ironfan::KnifeCommon
      deps do
        Ironfan::KnifeCommon.load_deps
      end

      banner "knife cluster show        CLUSTER[-FACET[-INDEXES]] (options) - a helpful display of cluster's cloud and chef state"

      option :cloud,
        :long        => "--[no-]cloud",
        :description => "Look up computers on AWS cloud (default is yes, look up computers; use --no-cloud to skip)",
        :default     => true,
        :boolean     => true

      def run
        with_verbosity(1){ config[:include_terminated] = true }
        load_ironfan
        die(banner) if @name_args.empty?
        configure_dry_run

        # Load the cluster/facet/slice/whatever
        target = get_slice(* @name_args)

        dump_command_config
        dump_chef_config
        #
        target.each do |computer|
          dump_computer(computer)
        end

        # Display same
        display(target)
      end

    protected

      def dump_computer(computer)
        header = "Computer #{computer.name} (#{computer.class})"
        with_verbosity 1 do
          Chef::Log.info(header)
          Chef::Log.info(MultiJson.encode(computer.server.canonical_machine_manifest_hash, pretty: true))
        end
        with_verbosity 2 do
          dump(header, computer.to_wire)
        end
      end

      def dump_command_config
        with_verbosity 2 do
          Chef::Log.info( ["", "*"*50, "", "Command Config", ""].join("\n") )
          dump("Command config", self.config)
        end
      end

      def dump_chef_config
        with_verbosity 2 do
          chef_config_hash = Hash[Chef::Config.keys.map{|key| [key, Chef::Config[key]]}]
          dump("Chef Config", chef_config_hash)
        end
      end

      def dump(title, hsh)
        Chef::Log.info( ["", "*"*50, "", "#{title}: ", ""].join("\n") )
        Chef::Log.info( MultiJson.dump(hsh, pretty: true ) )
      end

      def with_verbosity(num)
        yield if config[:verbosity] >= num
      end

    end
  end
end
