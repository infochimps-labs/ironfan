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
require 'yaml'

class Chef
  class Knife
    class EnvironmentFromRealm < Knife
      include Ironfan::KnifeCommon
      deps do
        Ironfan::KnifeCommon.load_deps
      end

      banner "knife environment from realm        realm (options) - syncs a realm's environment"

      option :dry_run,
        :long        => "--dry-run",
        :description => "Don't really run, just use mock calls",
        :boolean     => true,
        :default     => false

      def _run
        load_ironfan
        die(banner) unless @name_args.size == 1
        configure_dry_run

        # Load the cluster/facet/slice/whatever
        target = Ironfan.load_realm(* @name_args)

        env = Chef::Environment.new.tap do |env|
          env.name target.name
          env.description "Ironfan-created environment for #{target.name} realm"
          Chef::Log.info "pinning cookbooks in #{target.name} realm"
          target.cookbook_reqs.each do |cookbook, version|
            Chef::Log.info "  pinning cookbook #{cookbook} #{version}"
            env.cookbook cookbook, version
          end
        end

        env.save unless config[:dry_run]
      end
    end
  end
end
