module Ironfan
  class Provider

    class ChefServer < Ironfan::Provider
      collection :nodes,      Ironfan::Provider::ChefServer::Node
      collection :clients,    Ironfan::Provider::ChefServer::Client

      def discover!(cluster)
        discover_nodes! cluster
        discover_clients! cluster
      end
      
      def discover_nodes!(cluster)
        return nodes unless nodes.empty?
        Chef::Node.list(true).each_value do |node|
          nodes << Node.new(:adaptee => node) unless node.blank?
        end
        nodes
      end

      def discover_clients!(cluster)
        return clients unless clients.empty?
        Chef::ApiClient.list(true).each_value do |api_client|
          clients << Client.new(:adaptee => api_client) unless api_client.blank?
        end
        clients
      end

      # for all chef nodes that match the cluster,
      #   find a machine that matches and attach,
      #   or make a new machine and mark it :unexpected_node
      # for all chef clients that match
      #     find a machine that matches and attach,
      def correlate(cluster,machines)
        clients_matching(cluster).each do |client|
          match = machines.select {|m| client.matches_dsl? m.server }.first
          if match.nil?
            fake = Ironfan::Broker::Machine.new
            fake.name = client.name
            fake.bogosity = :unexpected_client
            machines << fake
          else
            match[:client] = client
          end
        end
        nodes_matching(cluster).each do |node|
          match = machines.select {|m| node.matches_dsl? m.server }.first
          if match.nil?
            fake = Ironfan::Broker::Machine.new
            fake.name = node.name
            fake.bogosity = :unexpected_node
            machines << fake
          else
            match[:node] = node
          end
        end
        machines
      end
      def nodes_matching(selector)
        nodes.values.select {|n| n.matches_dsl? selector, :strict=>false }
      end
      def clients_matching(selector)
        clients.values.select {|c| c.matches_dsl? selector, :strict=>false }
      end

      def sync!(machines)
        sync_roles! machines
        machines.each do |machine|
          ensure_node machine
          machine[:node].sync! machine
          ensure_client machine
          machine[:client].sync! machine
          raise 'incomplete'
        end
      end
      def sync_roles!(machines)
        defs = []
        machines.each do |m|
          defs << m.server.cluster_role
          defs << m.server.facet_role
        end
        defs = defs.compact.uniq

        defs.each{|d| Role.new(:expected => d).save}
      end
      def ensure_node(machine)
        return machine[:node] if machine.include? :node
        machine[:node] = node(machine.name)
      end
    end

  end
end