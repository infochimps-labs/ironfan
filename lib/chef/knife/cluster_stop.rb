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

require File.expand_path('ironfan_script', File.dirname(File.realdirpath(__FILE__)))

class Chef
  class Knife
    class ClusterStop < Ironfan::Script
      import_banner_and_options(Ironfan::Script)

      def relevant?(server)
        (not bogus?) && server.running?
      end

      def perform_execution(target)
        section("Stopping computers")
        super(target)
      end

      def confirm_execution(target)
        ui.info "  Unless these nodes are backed by EBS volumes, this will result in loss of all data"
        ui.info "  not saved elsewhere. Even if they are EBS backed, there may still be some data loss."
        if target.any?(&:permanent?)
          ui.warn "These servers are marked as 'permanent=true': #{ui.color(target.select(&:permanent?).map(&:name).join('.'), :red)}"
        end
        confirm_or_exit("Are you absolutely certain that you want to perform this action? (Type 'Yes' to confirm) ", 'Yes')
      end
    end
  end
end
