module Ironfan
  class Provider

    class Ec2 < Ironfan::IaasProvider
      field :adaptee, Whatever

      def initialize(*args,&block)
        super
        self.adaptee = Fog::Compute.new({
          :provider              => 'AWS',
          :aws_access_key_id     => Chef::Config[:knife][:aws_access_key_id],
          :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
          :region                => Chef::Config[:knife][:region]
        })
      end

      def discover!(cluster)
        discover_instances! cluster
        #discover_ebs_volumes!
          # Walk the list of servers, asking each to discover its volumes.
        #discover_security_groups!
        #discover_key_pairs!
        #discover_placement_groups!
      end
      
      def discover_instances!(cluster)
        return instances unless instances.empty?
        adaptee.servers.each do |fs| 
          instances << Instance.new(:adaptee => fs) unless fs.blank?
        end
        instances
      end

      # An instance matches if the Name tag starts with the selector's fullname
      def instances_of(selector)
        instances.values.select {|i| i.name.match("^#{selector.fullname}") }
      end

      # for each instance that matches the cluster,
      #   find a machine that matches
      #     attach instance to machine if there isn't one,
      #     or make another and mark both :duplicate_instance
      #   or make a new machine and mark it :unexpected_instance
      def correlate(cluster,machines)
        instances_of(cluster).each do |instance|
          match = machines.values.select {|m| instance.matches? m }.first
          if match.nil?
            match = Ironfan::Broker::Machine.new
            match.name     = instance.name
            match.bogosity = :unexpected_instance
            machines << match
          end
          if match.include? :instance
            match.bogosity = :duplicate_instance
            copy = match.dup
            machines << copy
          end
          match[:instance] = instance
        end
      end


      def sync!(machines)
#       sync_keypairs
#       sync_security_groups
#       delegate_to_servers( :sync_to_cloud )
        # Only sync Ec2::Instances
        sync_keypairs! machines
        sync_security_groups! machines
        target = machines.select{|m| m[:instance].class == Instance}
        target.each(&:sync!)
        raise 'incomplete'
      end
      def sync_keypairs!(machines)
#         step("ensuring keypairs exist")
#         keypairs  = servers.map{|svr| [svr.cluster.cloud.keypair, svr.cloud.keypair] }.flatten.map(&:to_s).reject(&:blank?).uniq
#         keypairs  = keypairs - Ironfan.fog_keypairs.keys
#         keypairs.each do |keypair_name|
#           keypair_obj = Ironfan::Ec2Keypair.create!(keypair_name)
#           Ironfan.fog_keypairs[keypair_name] = keypair_obj
#         end
        raise 'unimplemented'
      end
      def sync_security_groups!(machines)
        raise 'unimplemented'
      end
    end

  end
end