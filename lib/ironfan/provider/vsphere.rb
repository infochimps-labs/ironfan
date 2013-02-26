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
        @@connection ||=  RbVmomi::VIM.connect(self.vsphere_credentials)
      end

      def self.find_dc(vsphere_dc)
        connection.serviceInstance.find_datacenter(vsphere_dc)
      end

      def self.find_in_folder(folder, type, name)
        folder.childEntity.grep(type).find { |o| o.name == name }
      end

      def self.get_rspec(dc)
        hosts = find_all_in_folder(dc.hostFolder, RbVmomi::VIM::ComputeResource)
        resource_pool = hosts.first.resourcePool
        RbVmomi::VIM.VirtualMachineRelocateSpec(:pool => resource_pool)
      end

      def self.find_all_in_folder(folder, type)
        if folder.instance_of?(RbVmomi::VIM::ClusterComputeResource)
          folder = folder.resourcePool
        end

        if folder.instance_of?(RbVmomi::VIM::ResourcePool)
          folder.resourcePool.grep(type)
        elsif folder.instance_of?(RbVmomi::VIM::Folder)
          folder.childEntity.grep(type)
        else
          puts "Unknown type #{folder.class}, not enumerating"
          nil
        end
     end

     def self.find_network(network, dc)
       baseEntity = dc.network
       baseEntity.find { |f| f.name == network }
     end

      private
      def self.vsphere_credentials
        return {
          :user                  => Chef::Config[:knife][:vsphere_username],
          :password              => Chef::Config[:knife][:vsphere_password],
          :host                  => Chef::Config[:knife][:vsphere_server],
          :insecure              => Chef::Config[:knife][:vsphere_insecure] || true
        }
      end
    end
  end
end

