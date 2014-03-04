module Ironfan
  class Provider

    class Autoscale < Ironfan::IaasProvider
      self.handle = :autoscale

      def self.resources
        [ Machine, Ironfan::Provider::Ec2::SecurityGroup ]
      end

      #
      # Utility functions
      #
      def self.connection
        @@autoscaling ||= Fog::AWS::AutoScaling.new(self.aws_credentials)
      end

      def self.aws_account_id()
        Chef::Config[:knife][:aws_account_id]
      end

      def self.applicable(computer)
        computer.server and computer.server.clouds.include?(:autoscale)
      end

      private

      def self.aws_credentials
        {
          :aws_access_key_id     => Chef::Config[:knife][:aws_access_key_id],
          :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
          :region                => Chef::Config[:knife][:region]
        }
      end

    end
  end
end
