module Ironfan
  class Provider

    class Ec2 < Ironfan::IaasProvider
      field :types,    Array,  :default =>
        [ :instances, :ebs_volumes, :security_groups, :key_pairs, :placement_groups ]
#       field :types,    Array,  :default => [ :instances, :ebs_volumes ]
#       field :discover, Array,  :default =>->{types + []}

      collection :instances,            Ironfan::Provider::Ec2::Instance
      collection :ebs_volumes,          Ironfan::Provider::Ec2::EbsVolume
      collection :key_pairs,            Ironfan::Provider::Ec2::KeyPair
      collection :placement_groups,     Ironfan::Provider::Ec2::PlacementGroup
      collection :security_groups,      Ironfan::Provider::Ec2::SecurityGroup

      def initialize(*args,&block)
        super
        @instances =            Ironfan::Provider::Ec2::Instances.new
        @ebs_volumes =          Ironfan::Provider::Ec2::EbsVolumes.new
        @security_groups =      Ironfan::Provider::Ec2::SecurityGroups.new
        @key_pairs =            Ironfan::Provider::Ec2::KeyPairs.new
        @placement_groups =     Ironfan::Provider::Ec2::PlacementGroups.new
      end

      def self.connection
        @@connection ||= Fog::Compute.new({
          :provider              => 'AWS',
          :aws_access_key_id     => Chef::Config[:knife][:aws_access_key_id],
          :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
          :region                => Chef::Config[:knife][:region]
        })
      end

#       def sync!(machines)
# #       sync_keypairs
# #       sync_security_groups
# #       delegate_to_servers( :sync_to_cloud )
#         # Only sync Ec2::Instances
#         sync_keypairs! machines
#         sync_security_groups! machines
#         target = machines.select{|m| m[:instance].class == Instance}
#         target.each(&:sync!)
#         raise 'incomplete'
#       end
#       def sync_keypairs!(machines)
# #         step("ensuring keypairs exist")
# #         keypairs  = servers.map{|svr| [svr.cluster.cloud.keypair, svr.cloud.keypair] }.flatten.map(&:to_s).reject(&:blank?).uniq
# #         keypairs  = keypairs - Ironfan.fog_keypairs.keys
# #         keypairs.each do |keypair_name|
# #           keypair_obj = Ironfan::Ec2Keypair.create!(keypair_name)
# #           Ironfan.fog_keypairs[keypair_name] = keypair_obj
# #         end
#         raise 'unimplemented'
#       end
#       def sync_security_groups!(machines)
#         raise 'unimplemented'
#       end
    end

  end
end