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
    class ClusterList < Knife
      include Ironfan::KnifeCommon

      deps do
        require 'formatador'
      end

      banner 'knife cluster list (options)'

      option :facets,
        :long        => '--with-facets',
        :description => 'List cluster facets along with names and paths',
        :default     => false,
        :boolean     => true
      
      def run
        load_ironfan
        configure_dry_run

        data = Ironfan.cluster_filenames.map do |name, path|
          as_table = { :cluster => name, :path => path }
          if config[:facets]
            facets = Ironfan.load_cluster(name).facets.to_a.map(&:name).join(', ')
            as_table.merge!(:facets => facets)
          end
          as_table
        end

        ui.info "Cluster Path: #{ Ironfan.cluster_path.join ", " }"
        headers = config[:facets] ? [:cluster, :facets, :path] : [:cluster, :path] 
        Formatador.display_compact_table(data, headers)
      end
    end
  end
end
