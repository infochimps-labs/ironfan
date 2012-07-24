# This module is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers, to control instance life-cycle and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for 
#   them.
module Ironfan

  class Broker < Builder
    field :chef,              Ironfan::Provider::ChefServer,
          :default =>         Ironfan::Provider::ChefServer.new
    collection :providers,    Ironfan::IaasProvider

    #
    #   PUBLIC METHODS
    #

    # Take in a Dsl::Cluster, return Machines populated with
    #   all discovered resources that correlate, plus bogus machines
    #   corresponding to 
    def discover!(cluster)
      machines =                Machines.new

      # Get fully resolved servers
      machines.cluster =        cluster.resolve
      servers =                 machines.cluster.servers

      servers.each do |server|
        # ensure that each chosen provider is available
        provider(server.selected_cloud.name)

        # set up a bare machine
        m = Machine.new
        m.server = server
        machines << m
      end

      delegate_to all_providers, :load! => machines
      delegate_to all_providers, :correlate! => machines
      delegate_to all_providers, :validate! => machines
      machines
    end

    def display(machines,style)
      defined_data = machines.map {|m| m.to_display(style) }
      if defined_data.empty?
        ui.info "Nothing to report"
      else
        headings = defined_data.map{|r| r.keys}.flatten.uniq
        Formatador.display_compact_table(defined_data, headings.to_a)
      end
    end

    def kill!(machines,selector=nil)
      targets = case selector
        when nil        then all_providers
        when :chef      then chef
        when :providers then providers.values
      end
        
      delegate_to targets, :destroy! => machines
    end

    def launch!(machines)
      sync_to_chef! machines
      create_dependencies! machines
      create_instances! machines
      sync! machines
    end

    def stop!(machines)
      delegate_to providers.values, :stop_instances! => machines
      sync_to_chef! machines
    end

    def start!(machines)
      sync_to_chef! machines
      create_dependencies! machines
      delegate_to providers.values, :start_instances! => machines
      sync! machines
    end

    # TODO: Parallelize
    def sync!(machines)
      delegate_to all_providers, :save! => machines
    end
    def sync_to_chef!(machines)
      delegate_to chef, :save! => machines
    end
    def sync_to_providers!(machines)
      delegate_to providers.values, :save! => machines
    end

    #
    #   PERSONAL METHODS
    #

    def all_providers() [chef, providers.values].flatten; end

    def create_dependencies!(machines)
      delegate_to all_providers, :create_dependencies! => machines
    end

    # Do serially ensure node is created before instance
    def create_instances!(machines)
      delegate_to chef, :create_instances! => machines
      delegate_to providers.values, :create_instances! => machines
    end
  end

end