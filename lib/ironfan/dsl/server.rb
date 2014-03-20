module Ironfan
  class Dsl

    class MachineManifest
      include Gorillib::Model

      # base server fields
      field :environment, Symbol
      field :name, String
      field :cluster_name, String
      field :realm_name, String
      field :facet_name, String
      field :components, Array, of: Ironfan::Dsl::Component, default: []
      field :run_list, Array, of: String, default: []
      field :cluster_default_attributes, Hash
      field :cluster_override_attributes, Hash
      field :facet_default_attributes, Hash
      field :facet_override_attributes, Hash

      # cloud fields
      field :cloud_name,                String
      field :availability_zones,        Array, default: []
      field :backing,                   String
      field :ebs_optimized,             :boolean
      field :flavor,                    String
      field :image_id,                  String
      field :placement_group,           String
      field :elastic_ip,                String
      field :auto_elastic_ip,           String
      field :allocation_id,             String
      field :region,                    String
      field :ssh_user,                  String
      field :subnet,                    String
      field :vpc,                       String

      #-----------------------------------------------------------------------------------
      # # FIXME: I haven't determined how to pull some of these fields
      # #        in from the remote machines. In fact, some of these
      # #        will have to be omitted when comparing. Since
      # #        they'll only be necessary when we refactor the
      # #        backend to accept manifests for launch, I'm going
      # #        to leave these commented out for now. --josh
      #
      # # base server fields
      #
      # field :volumes, Array, of: Volume
      #
      # # cloud fields 
      #
      # field :bits,                      Integer
      # field :bootstrap_distro,          String
      # field :chef_client_script,        String
      # field :default_availability_zone, String
      # field :elastic_load_balancers,    Array, of: Ironfan::Dsl::Ec2::ElasticLoadBalancer, default: []
      # field :iam_server_certificates,   Array, of: Ironfan::Dsl::Ec2::IamServerCertificate, default: []
      # field :image_name,                String
      # field :keypair,                   String
      # field :monitoring,                String
      # field :mount_ephemerals,          Hash
      # field :permanent,                 :boolean
      # field :provider,                  Whatever
      # field :security_groups,           Array, of: Ironfan::Dsl::Ec2::SecurityGroup
      # field :ssh_identity_dir,          String
      # field :validation_key,            String
      #-----------------------------------------------------------------------------------

     
      # Reconstruct machine manifest from a computer, pulling
      # information from remote sources as necessary.
      def self.from_computer(computer)
        node = get_node(computer.name)
        cluster_name = node['cluster_name']
        Chef::Log.info "name is whoa: #{cluster_name}"
        facet_name = node['facet_name']
        instance = node['facet_index']

        from_remote(
                    cluster_name,
                    facet_name,
                    instance,
                    node,
                    computer.machine,
                    computer.server.clouds.to_a.first,
                    get_role("#{cluster_name}-cluster"),
                    get_role("#{cluster_name}-#{facet_name}-facet")
                  )
      end

      def self.from_remote(cluster_name,
                           facet_name,
                           instance,
                           node,
                           machine,
                           cloud,
                           cluster_role,
                           facet_role)
        machine = NilCheckDelegate.new(machine)
        cloud = NilCheckDelegate.new(cloud)
        cluster_role = NilCheckDelegate.new(cluster_role)
        facet_role = NilCheckDelegate.new(facet_role)

        result = Ironfan::Dsl::MachineManifest.
          receive(

                  # base server fields

                  environment: node.chef_environment,
                  name: instance,
                  cluster_name: cluster_name,
                  facet_name: facet_name,
                  components: remote_components(node),
                  run_list: remote_run_list(node),
                  cluster_default_attributes: (cluster_role.default_attributes || {}),
                  cluster_override_attributes: (cluster_role.override_attributes || {}),
                  facet_default_attributes: (facet_role.default_attributes || {}),
                  facet_override_attributes: (facet_role.override_attributes || {}),

                  # cloud fields

                  backing: machine.root_device_type,
                  cloud_name: cloud.name,
                  availability_zones: [*machine.availability_zone],
                  ebs_optimized: machine.ebs_optimized,
                  flavor: machine.flavor_id,
                  image_id: machine.image_id,
                  keypair: machine.nilcheck_depth(1).key_pair.name,
                  monitoring: machine.monitoring,
                  placement_group: machine.placement_group,
                  region: machine.availability_zone.to_s[/.*-.*-\d+/],
                  security_groups: machine.nilcheck_depth(1).groups.map{|x| {name: x}},
                  subnet: machine.subnet_id,
                  vpc: machine.vpc_id

                  #-----------------------------------------------------------------------------------
                  # # FIXME: I haven't determined how to pull some of these fields
                  # #        in from the remote machines. In fact, some of these
                  # #        will have to be omitted when comparing. Since
                  # #        they'll only be necessary when we refactor the
                  # #        backend to accept manifests for launch, I'm going
                  # #        to leave these commented out for now. --josh
                  #
                  # # base server fields
                  #
                  # volume: local_manifest.volume
                  #
                  # # cloud fields 
                  #
                  # bits: local_manifest.bits,
                  # bootstrap_distro: local_manifest.bootstrap_distro,
                  # chef_client_script: local_manifest.chef_client_script,                  
                  # default_availability_zone: local_manifest.default_availability_zone,
                  # iam_server_certificates: launch_description.fetch(:iam_server_certificates),
                  # image_name: local_manifest.image_name,
                  # elastic_load_balancers: launch_description.fetch(:elastic_load_balancers),
                  # mount_ephemerals: local_manifest.mount_ephemerals,
                  # permanent: local_manifest.permanent,
                  # provider: local_manifest.provider,
                  # elastic_ip: local_manifest.elastic_ip,
                  # auto_elastic_ip: local_manifest.auto_elastic_ip,
                  # allocation_id: local_manifest.allocation_id,
                  # ssh_user: local_manifest.ssh_user,
                  # ssh_identity_dir: local_manifest.ssh_identity_dir,
                  # validation_key: local_manifest.validation_key,
                  #-----------------------------------------------------------------------------------
                  )
      end

      def to_comparable
        deep_stringify(to_wire.tap do |hsh|
                         hsh.delete(:_type)
                         hsh.delete(:ssh_user)
                         #hsh[:security_groups] = Hash[hsh[:security_groups].map{|x| [x.fetch(:name), x]}]
                         hsh[:components] = Hash[hsh.fetch(:components).map do |component|
                                                   [component.fetch(:name), component]
                                                 end]
                         hsh[:run_list] = hsh.fetch(:run_list).map do |x|
                           x.end_with?(']') ? x : "recipe[#{x}]"
                         end
                       end)
      end

      private

      def deep_stringify obj
        case obj
        when Hash then Hash[obj.map{|k,v| [k.to_s, deep_stringify(v)]}]
        when Array then obj.map{|x| deep_stringify(x)}
        when Symbol then obj.to_s
        else obj
        end
      end

      def self.get_node(node_name)
        Chef::Node.load(node_name)
      rescue Net::HTTPServerException => ex
        Chef::Node.new
      end

      def self.get_role(role_name)
        Chef::Role.load(role_name)
      rescue Net::HTTPServerException => ex
        Chef::Role.new
      end

      def self.remote_components(node)
        announcements = node['components'] || {}
        node['components'].to_a.map do |_, announce|
          name = announce['name'].to_sym
          plugin = Ironfan::Dsl::Compute.plugin_for(name)
          plugin.from_node(node).tap{|x| x.name = name} if plugin
        end.compact
      end

      def self.remote_run_list(node)
        node.run_list.to_a.map(&:to_s)
      end
    end

    class Server < Ironfan::Dsl::Compute
      field      :cluster_name, String
      field      :facet_name,   String

      def initialize(attrs={},&block)
        unless attrs[:owner].nil?
          self.realm_name       attrs[:owner].realm_name
          self.cluster_name =   attrs[:owner].cluster_name
          self.facet_name =     attrs[:owner].name

          self.role     Compute.cluster_role_name(realm_name, cluster_name), :last
          self.role     Compute.facet_role_name(realm_name, cluster_name, facet_name), :last
        end
        super
      end

      def keypair_name
        full_cluster_name
      end

      def full_cluster_name
          "#{realm_name}-#{cluster_name}"
      end

      def full_name
        "#{full_cluster_name}-#{facet_name}-#{name}"
      end
      def host_name()           full_name.gsub('_','-'); end;
      def fqdn()                [self.host_name, self.dns_domain].compact.join(".");     end

      def index()               name.to_i;                                      end
      def implied_volumes()    selected_cloud.implied_volumes;                 end

      def to_display(style,values={})
        selected_cloud.to_display(style,values)

        return values if style == :minimal

        values["Env"]   = environment
        values["Realm"] = realm_name
        values
      end

      # we should always show up in owners' inspect string
      def inspect_compact ; inspect ; end

      # @returns [Hash{String, Array}] of 'what you did wrong' => [relevant, info]
      def lint
        errors = []
        errors['missing cluster/facet/server'] = [cluster_name, facet_name, name] unless (cluster_name && facet_name && name)
        errors
      end

      def to_machine_manifest
        cloud = clouds.each.to_a.first
        MachineManifest.receive(

                                # base server fields

                                environment: environment,
                                name: name,
                                cluster_name: cluster_name,
                                facet_name: facet_name,
                                run_list: run_list,
                                components: components,
                                cluster_default_attributes: cluster_role.default_attributes,
                                cluster_override_attributes: cluster_role.override_attributes,
                                facet_default_attributes: facet_role.default_attributes,
                                facet_override_attributes: facet_role.override_attributes,
                                volumes: volumes,

                                # cloud fields

                                cloud_name: cloud.name,

                                availability_zones: cloud.availability_zones,
                                backing: cloud.backing,
                                bits: cloud.bits,
                                bootstrap_distro: cloud.bootstrap_distro,
                                chef_client_script: cloud.chef_client_script,
                                default_availability_zone: cloud.default_availability_zone,
                                elastic_load_balancers: cloud.respond_to?(:elastic_load_balancers) ? cloud.elastic_load_balancers : nil,
                                ebs_optimized: cloud.ebs_optimized,
                                flavor: cloud.flavor,
                                iam_server_certificates: cloud.respond_to?(:iam_server_certificates) ? cloud.iam_server_certificates : nil,
                                image_id: cloud.image_id,
                                image_name: cloud.image_name,
                                keypair: cloud.keypair,
                                monitoring: cloud.monitoring,
                                mount_ephemerals: cloud.mount_ephemerals,
                                permanent: cloud.permanent,
                                placement_group: cloud.placement_group,
                                provider: cloud.provider,
                                elastic_ip: cloud.elastic_ip,
                                auto_elastic_ip: cloud.auto_elastic_ip,
                                allocation_id: cloud.allocation_id,
                                region: cloud.region,
                                security_groups: cloud.security_groups,
                                ssh_user: cloud.ssh_user,
                                ssh_identity_dir: cloud.ssh_identity_dir,
                                subnet: cloud.subnet,
                                validation_key: cloud.validation_key,
                                vpc: cloud.vpc

                                )
      end

      def canonical_machine_manifest_hash
        self.class.canonicalize(to_machine_manifest)
      end

      private

      def self.canonicalize(item)
        case item
        when Array, Gorillib::ModelCollection
          item.each.map{|i| canonicalize(i)}
        when Ironfan::Dsl::Component
          canonicalize(item.to_manifest)
        when Gorillib::Builder, Gorillib::Model
          canonicalize(item.to_wire.tap{|x| x.delete(:_type)})
        when Hash then
          Hash[item.sort.map{|k,v| [k, canonicalize(v)]}]
        else
          item
        end
      end
    end

  end
end
