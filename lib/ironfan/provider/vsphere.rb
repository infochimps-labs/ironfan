module Ironfan
  class Provider

    class Vsphere < Ironfan::IaasProvider
      self.handle = :vsphere

      def self.resources()
        [ Machine ]
      end

      #
      # Utility functions
      #
      def self.connection
        @@connection ||= Fog::Compute.new(self.vsphere_credentials.merge({ :provider => 'vsphere' }))
        puts "Connected"
      end

      private
      def self.vsphere_credentials
        return {
          :vsphere_username      => Chef::Config[:knife][:vsphere_username],
          :vsphere_password      => Chef::Config[:knife][:vsphere_password],
          :vsphere_server        => Chef::Config[:knife][:vsphere_server],
          :vsphere_expected_pubkey_hash => Chef::Config[:knife][:vsphere_expected_pubkey_hash]
        }
      end
    end
  end
end

