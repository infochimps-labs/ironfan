# This class is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers to survey the existing machines and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for 
#   them.
module Ironfan
  class ProviderBroker
    def discover(cluster)
      # resolve all of the individual server definitions
      servers = []
      cluster.facets.each{|f| f.servers.each{|s| servers << s.resolve }}
      
      # for each server, determine target cloud and singleton a provider for it
      servers.each do |s|
        cloud = s.selected_cloud
      end
      # for each provider, go looking for machines (& other things?) associated with the cluster
      # for each machine associated with the cluster, find corresponding server or mark bogus
      # (for each other thing, find corresponding machine or mark bogus?)
      raise NotImplementedError, 'ProviderBroker.new.discover(cluster) not written yet'
    end
  end
end