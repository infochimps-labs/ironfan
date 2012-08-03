module Ironfan
  class Provider

    class Ec2 < Ironfan::IaasProvider
      field :types,     Array,  :default => 
        [ :instances, :ebs_volumes, :elastic_ips, :key_pairs,
          :placement_groups, :security_groups ]
      field :discover,  Array,  :default => [ :instances ]

      collection :instances,            Ironfan::Provider::Ec2::Instance
      collection :ebs_volumes,          Ironfan::Provider::Ec2::EbsVolume
      collection :elastic_ips,          Ironfan::Provider::Ec2::ElasticIp
      collection :key_pairs,            Ironfan::Provider::Ec2::KeyPair
      collection :placement_groups,     Ironfan::Provider::Ec2::PlacementGroup
      collection :security_groups,      Ironfan::Provider::Ec2::SecurityGroup

      def initialize(*args,&block)
        super
        @ebs_volumes =                  Ironfan::Provider::Ec2::EbsVolumes.new
        @elastic_ips =                  Ironfan::Provider::Ec2::ElasticIps.new
        @instances =                    Ironfan::Provider::Ec2::Instances.new
        @key_pairs =                    Ironfan::Provider::Ec2::KeyPairs.new
        @placement_groups =             Ironfan::Provider::Ec2::PlacementGroups.new
        @security_groups =              Ironfan::Provider::Ec2::SecurityGroups.new
      end

      #
      # Discovery
      #
      def load!(machines)
        targets = [ instances, ebs_volumes, security_groups, key_pairs ]
        delegate_to(targets) { load! machines }
      end

      def correlate!(machines)
        targets = [ instances, ebs_volumes ]
        delegate_to(targets) { correlate! machines }
      end

      # nothing here actually needs validation, currently
      def validate!(machines)
        #delegate_to(ebs_volumes) { validate! machines }
      end

      # 
      # Manipulation
      #
      def create_dependencies!(machines)
        targets = [ key_pairs, security_groups ]
        #targets = [ security_groups ]
        delegate_to(targets) { create! machines }
      end

      def create_instances!(machines)
        delegate_to(instances) { create! machines }
      end

      def destroy!(machines)
        delegate_to(instances) { destroy! machines }
      end

      def save!(machines)
        targets = [ instances, ebs_volumes, security_groups ]
        delegate_to(targets) { save! machines }
      end

      def start_instances!(machines)
        delegate_to(instances) { start! machines }
      end

      def stop_instances!(machines)
        delegate_to(instances) { stop! machines }
      end

      #
      # Utility functions
      #
      def self.connection
        @@connection ||= Fog::Compute.new({
          :provider              => 'AWS',
          :aws_access_key_id     => Chef::Config[:knife][:aws_access_key_id],
          :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
          :region                => Chef::Config[:knife][:region]
        })
      end

      # Ensure that a fog object (instance, volume, etc.) has the proper tags on it
      def self.ensure_tags(tags,fog)
        tags.delete_if {|k, v| fog.tags[k] == v.to_s  rescue false }
        return if tags.empty?

        Ironfan.step(fog.name,"tagging with #{tags.inspect}", :green)
        tags.each do |k, v|
          Chef::Log.debug( "tagging #{fog.name} with #{k} = #{v}" )
          Ironfan.safely do
            config = {:key => k, :value => v.to_s, :resource_id => fog.id }
            connection.tags.create(config)
          end
        end
      end

      def self.applicable(machines)
        machines.values.select do |machine|
          machine.server and machine.server.clouds.include?(:ec2)
        end
      end
    end

  end
end