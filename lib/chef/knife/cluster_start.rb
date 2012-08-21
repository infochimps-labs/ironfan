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

require File.expand_path('ironfan_script',       File.dirname(File.realdirpath(__FILE__)))

class Chef
  class Knife
    class ClusterStart < Ironfan::Script
      import_banner_and_options(Ironfan::Script)

      def relevant?(server)
        server.stopped?
      end

      def perform_execution(target)
        section("Starting computers")
        super(target)
      end

    end
  end
end
