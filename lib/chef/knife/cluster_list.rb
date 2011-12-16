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

require File.expand_path(File.dirname(__FILE__)+"/knife_common.rb")

class Chef
  class Knife
    class ClusterList < Knife
      include ClusterChef::KnifeCommon

      deps do
        require 'formatador'
      end

      banner "knife cluster list (options)"

      def run
        load_cluster_chef
        configure_dry_run

        hash = ClusterChef.cluster_filenames

        table = []
        hash.keys.sort.each do |key|
          table.push( { :cluster => key, :path => hash[key] } )
        end

        ui.info "Cluster Path: #{ ClusterChef.cluster_path.join ", " }"

        Formatador.display_compact_table(table, [:cluster,:path])

      end
    end
  end
end
