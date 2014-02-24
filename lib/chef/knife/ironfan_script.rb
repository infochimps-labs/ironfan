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
module Ironfan
  class Script < Chef::Knife
    include Ironfan::KnifeCommon

    deps do
      Ironfan::KnifeCommon.load_deps
    end

    option :dry_run,
      :long        => "--dry-run",
      :description => "Don't really run, just use mock calls",
      :boolean     => true,
      :default     => false
    option :yes,
      :long        => "--yes",
      :description => "Skip confirmation prompts on risky actions.",
      :boolean     => true

    def _run
      load_ironfan

      die(banner) if @name_args.empty?
      configure_dry_run

      target = get_relevant_slice(* @name_args)

      if prepares? and (prepares_on_noop? or not target.empty?)
        ui.info "Preparing shared resources:"
        all_computers(*@name_args).prepare
      end

      unless target.empty?
        ui.info(["\n",
                 ui.color("Running #{sub_command}", :cyan),
                 " on #{target.joined_names}..."].join())
        unless config[:yes]
          ui.info("")
          confirm_execution(target)
        end
        #
        perform_execution(target)
      end

      if healthy? and aggregates? and (aggregates_on_noop? or not target.empty?)
        ui.info "Applying aggregations:"
        all_computers(*@name_args).aggregate
      end

      if target.empty?
        ui.warn("No computers to #{sub_command}")
      else
        ui.info("")
        ui.info "Finished! Current state:"
        display(target)
      end
      #
      exit_if_unhealthy!
    end

    def perform_execution(target)
      target.send(sub_command)
    end

    def prepares?
      true
    end

    def prepares_on_noop?
      false
    end

    def aggregates?
      true
    end

    def aggregates_on_noop?
      false
    end
  end
end
