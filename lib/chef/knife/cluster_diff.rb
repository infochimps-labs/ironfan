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
        manifest = computer.server.to_machine_manifest
        node_name = "#{manifest.cluster_name}-#{manifest.facet_name}-#{manifest.name}"

        $stdout.puts("\nDisplaying component diffs for #{node_name}\n")

        node = 
          begin
            Chef::Node.load(node_name).to_hash
          rescue Net::HTTPServerException => ex
            {}
          end

        announcements = node['announces'] || {}
        remote_components = Hash[announcements.map do |_, announce|
                                   name = announce['name'].to_sym
                                   plugin = Ironfan::Dsl::Compute.plugin_for(name)
                                   [name, plugin.from_node(node)] if plugin
                                 end.compact]

        local_components = manifest.components

        differ = Gorillib::DiffFormatter.new(left: :local, right: :remote, stream: $stdout)
        differ.
          display_diff(Hash[remote_components.map{|k,v| [k, v.to_node]}],
                       Hash[local_components.each.map{|cp| [cp.name, cp.to_node]}])

        $stdout.puts("\nDisplaying run list diffs for #{node_name}\n")

        local_run_list = manifest.run_list.map do |item|
          item = item.to_s
          item.start_with?('role') ? item : "recipe[#{item}]"
        end

        differ.display_diff(local_run_list, node['run_list'].to_a.map(&:to_s))

        $stdout.puts("\nDisplaying cluster attribute diffs for #{node_name}\n")

        cluster_role = Chef::Role.load("#{manifest.cluster_name}-cluster")

        differ.display_diff(manifest.cluster_default_attributes,
                            cluster_role.default_attributes)

        $stdout.puts("\nDisplaying facet attribute diffs for #{node_name}\n")

        facet_role = Chef::Role.load("#{manifest.cluster_name}-#{manifest.facet_name}-facet")

        differ.display_diff(manifest.facet_default_attributes,
                            facet_role.default_attributes)
      end
    end
  end
end
