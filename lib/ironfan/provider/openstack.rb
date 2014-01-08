module Ironfan
  class Provider

    class OpenStack < Ironfan::IaasProvider
      self.handle = :openstack

      def self.resources
        [ Machine, Keypair, SecurityGroup ]
      end

      #
      # Utility functions
      #
      def self.connection
        @@connection ||= Fog::Compute.new(self.openstack_credentials.merge({ :provider => 'openstack' }))
      end


      #
      # Returns a hash that maps flavor names to flavors
      #
      def self.flavor_hash
        @@flavors ||= self.connection.flavors.inject({}){|h,f| h[f.name]=f; h }
      end

      #
      # Returns a hash that maps flavor ids to flavors
      #
      def self.flavor_id_hash
        @@flavor_ids ||= self.connection.flavors.inject({}){|h,f| h[f.id]=f; h }
      end


      # Ensure that a fog object (machine, volume, etc.) has the proper tags on it
      def self.ensure_tags(tags,fog)
        # openstack does not have tags.

        #tags.delete_if {|k, v| fog.tags[k] == v.to_s  rescue false }
        #return if tags.empty?

        #Ironfan.step(fog.name,"tagging with #{tags.inspect}", :green)
        #tags.each do |k, v|
        #  Chef::Log.debug( "tagging #{fog.name} with #{k} = #{v}" )
        #  Ironfan.safely do
        #    config = {:key => k, :value => v.to_s, :resource_id => fog.id }
        #    connection.tags.create(config)
        #  end
        #end
      end

      def self.applicable(computer)
        computer.server and computer.server.clouds.include?(:openstack)
      end

      private

      def self.openstack_credentials
        return {
          :openstack_api_key   =>   Chef::Config[:knife][:openstack_api_key],
          :openstack_username  =>   Chef::Config[:knife][:openstack_username],
          :openstack_auth_url  =>   Chef::Config[:knife][:openstack_auth_url],
          :openstack_tenant    =>   Chef::Config[:knife][:openstack_tenant],
          :openstack_region    =>   Chef::Config[:knife][:openstack_region],
        }
      end

    end
  end
end
