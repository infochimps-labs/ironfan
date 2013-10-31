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
          manifest = computer.server.to_machine_manifest
          display_diff(manifest, node(manifest))
        end
      end

    private

      def display_diff(manifest, node)
        header("Displaying component diffs for #{node_name(manifest)}")

        differ.display_diff(local_components(manifest), remote_components(node))

        header("Displaying run list diffs for #{node_name(manifest)}")

        differ.display_diff(local_run_list(manifest), remote_run_list(node))

        cluster_role = Chef::Role.load("#{manifest.cluster_name}-cluster")

        header("Displaying cluster default attribute diffs for #{node_name(manifest)}")

        differ.display_diff(manifest.cluster_default_attributes,
                            cluster_role.default_attributes)

        header("Displaying cluster override attribute diffs for #{node_name(manifest)}")

        differ.display_diff(manifest.cluster_override_attributes,
                            cluster_role.override_attributes)

        facet_role = Chef::Role.load("#{manifest.cluster_name}-#{manifest.facet_name}-facet")

        header("Displaying facet default attribute diffs for #{node_name(manifest)}")

        differ.display_diff(manifest.facet_default_attributes,
                            facet_role.default_attributes)

        header("Displaying facet override attribute diffs for #{node_name(manifest)}")

        differ.display_diff(manifest.facet_override_attributes,
                            facet_role.override_attributes)
      end

      #---------------------------------------------------------------------------------------------

      def diff_objs(type, local, remote)
        header("Displaying #{type} diffs for #{node_name(manifest)}")
        differ.display_diff(local, remote)
      end

      #---------------------------------------------------------------------------------------------

      def differ
        Gorillib::DiffFormatter.new(left: :local,
                                    right: :remote,
                                    stream: $stdout,
                                    indentation: 4)
      end

      def node(manifest)
        Chef::Node.load(node_name(manifest)).to_hash
      rescue Net::HTTPServerException => ex
        {}
      end

      def node_name(manifest)
        "#{manifest.cluster_name}-#{manifest.facet_name}-#{manifest.name}"
      end

      #---------------------------------------------------------------------------------------------

      def local_components(manifest)
        Hash[manifest.components.map{|comp| [comp.name, comp.to_node]}]
      end

      def remote_components(node)
        announcements = node['announces'] || {}
        Hash[node['announces'].to_a.map do |_, announce|
               name = announce['name'].to_sym
               plugin = Ironfan::Dsl::Compute.plugin_for(name)
               [name, plugin.from_node(node).to_node] if plugin
             end.compact]
      end

      #---------------------------------------------------------------------------------------------

      def local_run_list(manifest)
        manifest.run_list.map do |item|
          item = item.to_s
          item.start_with?('role') ? item : "recipe[#{item}]"
        end        
      end

      def remote_run_list(node)
        node['run_list'].to_a.map(&:to_s)
      end
    end

    def header str
      $stdout.puts("  #{'-' * 80}")
      $stdout.puts("  #{str}")
      $stdout.puts("  #{'-' * 80}")
    end
  end
end
