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

        target.each do |computer|
          local_manifest = computer.server.to_machine_manifest
          display_diff(local_manifest,
                       mk_remote_manifest(local_manifest, computer))
        end
      end

    private

      def display_diff(local_manifest, remote_manifest)
        header("diffing manifests: local #{node_name(local_manifest)} <-> remote #{node_name(remote_manifest)}")
        differ.display_diff(deep_stringify(local_manifest.to_hash),
                            deep_stringify(remote_manifest.to_hash))
      end

      #---------------------------------------------------------------------------------------------

      def mk_remote_manifest(local_manifest, computer)
        node_name = node_name(local_manifest)
        node = node(node_name)
        cluster_role = get_role("#{local_manifest.cluster_name}-cluster")
        facet_role = get_role("#{local_manifest.cluster_name}-#{local_manifest.facet_name}-facet")

        _, cluster_name, facet_name, instance = /^(.*)-(.*)-(.*)$/.match(node['name'].to_s).to_a

        machine = NilCheckDelegate.new(computer.machine)

        launch_description = Ironfan::Provider::Ec2::Machine.launch_description(computer)

        result = Ironfan::Dsl::MachineManifest.
          receive(name: instance,
                  cluster_name: cluster_name,
                  facet_name: facet_name,
                  components: remote_components(node),
                  run_list: remote_run_list(node),
                  cluster_default_attributes: cluster_role.fetch('default_attributes'),
                  cluster_override_attributes: cluster_role.fetch('override_attributes'),
                  facet_default_attributes: facet_role.fetch('default_attributes'),
                  facet_override_attributes: facet_role.fetch('override_attributes'),

                  # cloud fields

                  backing: machine.root_device_type,
                  cloud_name: local_manifest.cloud_name,
                  availability_zones: [*machine.availability_zone],
                  ebs_optimized: machine.ebs_optimized,
                  flavor: machine.flavor_id,
                  elastic_load_balancers: launch_description.fetch(:elastic_load_balancers),
                  iam_server_certificates: launch_description.fetch(:iam_server_certificates),
                  image_id: machine.image_id,
                  keypair: machine.nilcheck_depth(1).key_pair.name,
                  monitoring: machine.monitoring,
                  placement_group: machine.placement_group,
                  region: machine.availability_zone.to_s[/.*-.*-\d+/],
                  security_groups: machine.nilcheck_depth(1).groups.map{|x| {name: x}},
                  subnet: machine.subnet_id,
                  vpc: machine.vpc_id

                  # not sure where to get these from the machine
                  
                  # bits: local_manifest.bits,
                  # bootstrap_distro: local_manifest.bootstrap_distro,
                  # chef_client_script: local_manifest.chef_client_script,                  
                  # default_availability_zone: local_manifest.default_availability_zone,
                  # image_name: local_manifest.image_name,
                  # mount_ephemerals: local_manifest.mount_ephemerals,
                  # permanent: local_manifest.permanent,
                  # provider: local_manifest.provider,
                  # elastic_ip: local_manifest.elastic_ip,
                  # auto_elastic_ip: local_manifest.auto_elastic_ip,
                  # allocation_id: local_manifest.allocation_id,
                  # ssh_user: local_manifest.ssh_user,
                  # ssh_identity_dir: local_manifest.ssh_identity_dir,
                  # validation_key: local_manifest.validation_key,
                  )
      end

      #---------------------------------------------------------------------------------------------

      def get_role(role_name)
        @test_chef_data[role_name] || Chef::Role.load(role_name).to_hash
      end

      #---------------------------------------------------------------------------------------------

      def differ
        Gorillib::DiffFormatter.new(left: :local,
                                    right: :remote,
                                    stream: $stdout,
                                    indentation: 4)
      end

      def node(node_name)
        @test_chef_data[node_name] || Chef::Node.load(node_name).to_hash
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
        node['announces'].to_a.map do |_, announce|
          name = announce['name'].to_sym
          plugin = Ironfan::Dsl::Compute.plugin_for(name)
          plugin.from_node(node).tap{|x| x.name = name} if plugin
        end.compact
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

      #---------------------------------------------------------------------------------------------

      def deep_stringify obj
        case obj
        when Hash then Hash[obj.map{|k,v| [k.to_s, deep_stringify(v)]}]
        when Symbol then obj.to_s
        else obj
        end
      end
    end

    def header str
      $stdout.puts("  #{'-' * 80}")
      $stdout.puts("  #{str}")
      $stdout.puts("  #{'-' * 80}")
    end
  end
end
