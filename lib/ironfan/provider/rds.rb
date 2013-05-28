module Ironfan
  class Provider

    class Rds < Ironfan::IaasProvider
      self.handle = :rds

      def self.resources
        [ Machine, SecurityGroup ]
      end

      #
      # Utility functions
      #
      def self.connection
        @@connection ||=  Fog::AWS::RDS.new(self.aws_credentials)
      end

      def self.iam
        credentials = self.aws_credentials
        credentials.delete(:region)
        @@iam ||= Fog::AWS::IAM.new(credentials)
      end

      def self.aws_account_id()
        Chef::Config[:knife][:aws_account_id]
      end

      # Ensure that a fog object (machine, volume, etc.) has the proper tags on it
      def self.ensure_tags(tags, fog)
        tags.delete_if {|k, v| fog.tags[k] == v.to_s  rescue false }
        return if tags.empty?

        Ironfan.step(fog.id, "tagging with #{tags.inspect}", :green)
        fog.add_tags(tags)
      end

      def self.applicable(computer)
        computer.server and computer.server.clouds.include?(:rds)
      end

      private

      def self.aws_credentials
        return {
          :aws_access_key_id     => Chef::Config[:knife][:aws_access_key_id],
          :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
          :region                => Chef::Config[:knife][:region]
        }
      end

    end
  end
end
