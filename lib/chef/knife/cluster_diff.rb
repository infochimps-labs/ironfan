require 'gorillib/model/serialization'
require 'gorillib/nil_check_delegate'
require 'yaml'
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

      option :cache_file,
        :long        => "--cache_file FILE",
        :description => "file to load chef information from, for testing purposes"

      def run
        load_ironfan
        die(banner) if @name_args.empty?
        configure_dry_run

        @test_chef_data = 
          if config.has_key? :cache_file
            Hash[open(config.fetch(:cache_file)).readlines.map{|line| datum = MultiJson.load(line); [datum['name'], datum]}]
          else
            {}
          end
        
        # Load the cluster/facet/slice/whatever
        target = get_slice(* @name_args)

        exit(1) if self.class.mismatches?(target)
      end

      def self.mismatches?(target)
        target.any? do |computer|
          local_manifest = computer.server.to_machine_manifest
          remote_manifest = Ironfan::Dsl::MachineManifest.from_computer(computer)
          display_diff(local_manifest, remote_manifest)
          local_manifest != remote_manifest
        end
      end
      
    private

      def self.node_name(manifest)
        "#{manifest.cluster_name}-#{manifest.facet_name}-#{manifest.name}"
      end

      def self.display_diff(local_manifest, remote_manifest)
        header("diffing manifests: local #{node_name(local_manifest)} <-> remote #{node_name(remote_manifest)}")
        differ.display_diff(local_manifest.to_comparable, remote_manifest.to_comparable)
      end

      #---------------------------------------------------------------------------------------------

      def self.differ
        Gorillib::DiffFormatter.new(left: :local,
                                    right: :remote,
                                    stream: $stdout,
                                    indentation: 4)
      end

      def self.header str
        $stdout.puts("  #{'-' * 80}")
        $stdout.puts("  #{str}")
        $stdout.puts("  #{'-' * 80}")
      end
    end
  end
end
