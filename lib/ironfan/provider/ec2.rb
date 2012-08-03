module Ironfan
  class Provider

    class Ec2 < Ironfan::IaasProvider


      def resources()
        # [ Machine, EbsVolume, ElasticIp, KeyPair, PlacementGroup, SecurityGroup ]
        [ Machine, EbsVolume, KeyPair, SecurityGroup ]
      end

      #
      # Discovery
      #
      def load!(computers)
        delegate_to(resources) { load! computers }
      end

      def correlate!(computers)
        targets = [ Machine, EbsVolume ]
        delegate_to(targets) { correlate! computers }
      end

      # nothing here actually needs validation, currently
      def validate!(computers)
        delegate_to(Machine) { validate! computers }
      end

      # 
      # Manipulation
      #
      def create_dependencies!(computers)
        targets = [ KeyPair, SecurityGroup ]
        #targets = [ SecurityGroup ]
        delegate_to(targets) { create! computers }
      end

      def create_machines!(computers)
        delegate_to(Machine) { create! computers }
      end

      def destroy!(computers)
        delegate_to(Machine) { destroy! computers }
      end

      def save!(computers)
        targets = [ Machine, EbsVolume, SecurityGroup ]
        delegate_to(targets) { save! computers }
      end

      def start_machines!(computers)
        delegate_to(Machine) { start! computers }
      end

      def stop_machines!(computers)
        delegate_to(Machine) { stop! computers }
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
      
      def self.aws_account_id()
        Chef::Config[:knife][:aws_account_id]
      end

      # Ensure that a fog object (machine, volume, etc.) has the proper tags on it
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

      def self.applicable(computers)
        computers.values.select do |computer|
          computer.server and computer.server.clouds.include?(:ec2)
        end
      end
    end

  end
end