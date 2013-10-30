require_relative '../../gorillib/diff'

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
    class ClusterDiff < Knife
      include Ironfan::KnifeCommon
      deps do
        Ironfan::KnifeCommon.load_deps
      end

      banner "knife cluster diff        CLUSTER[-FACET[-INDEXES]] (options) - differences between a cluster and its realization"

      option :node_file,
        :long        => "--nodefile",
        :description => "file to load nodes from, for testing purposes",
        :boolean => false

      def run
        load_ironfan
        die(banner) if @name_args.empty?
        configure_dry_run

        # Load the cluster/facet/slice/whatever
        target = get_slice(* @name_args)

        target.each do |computer|
          display_diff(computer)
        end
      end

    protected

      def display_diff(computer)
        server = computer.server
        node_name = "#{server.cluster_name}-#{server.facet_name}-#{server.name}"

        $stdout.puts("\nDisplaying component diffs for #{node_name}\n")

        node = 
          begin
            Chef::Node.load(node_name).to_hash
          rescue Net::HTTPServerException => ex
            {}
          end

        announcements = node['announces'] || {}
        ocomponents = Hash[announcements.map do |_, announce|
                             name = announce['name'].to_sym
                             plugin = Ironfan::Dsl::Compute.plugin_for(name)
                             [name, plugin.from_node(node)] if plugin
                           end.compact]

        components = server.components

        Gorillib::DiffFormatter.new(left: :local, right: :remote, stream: $stdout).
          display_diff(Hash[ocomponents.map{|k,v| [k, v.to_node]}],
                       Hash[components.each.map{|cp| [cp.name, cp.to_node]}])
      end
    end
  end
end
