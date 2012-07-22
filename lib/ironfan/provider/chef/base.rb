module Ironfan
  class Provider

    class ChefServer < Ironfan::Provider
      field :types,    Array,    :default => [ :nodes, :clients ]

      collection :nodes,        Ironfan::Provider::ChefServer::Node
      collection :clients,      Ironfan::Provider::ChefServer::Client

      def initialize
        super
        @nodes          = Ironfan::Provider::ChefServer::Nodes.new
        @clients        = Ironfan::Provider::ChefServer::Clients.new
      end

#       def sync!(machines)
#         sync_roles! machines
#         machines.each do |machine|
#           ensure_node machine
#           machine[:node].sync! machine
#           ensure_client machine
#           machine[:client].sync! machine
#           raise 'incomplete'
#         end
#       end
#       def sync_roles!(machines)
#         defs = []
#         machines.each do |m|
#           defs << m.server.cluster_role
#           defs << m.server.facet_role
#         end
#         defs = defs.compact.uniq
# 
#         defs.each{|d| Role.new(:expected => d).save}
#       end
#       def ensure_node(machine)
#         return machine[:node] if machine.include? :node
#         machine[:node] = node(machine.name)
#       end
    end

  end
end