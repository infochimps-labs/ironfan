# This module is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers, to control instance life-cycle and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for 
#   them.
module Ironfan
  def self.broker
    @@broker ||= Ironfan::Broker.new
  end

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
      # Get fully resolved servers, and build Machines using them
      machines = Machines.new(:cluster => cluster.resolve)
      # ensure that each chosen provider is available
      machines.each {|m| provider(m.server.selected_cloud.name) }

      delegate_to(all_providers) { load! machines }
      delegate_to(all_providers) { correlate! machines }
      delegate_to(all_providers) { validate! machines }
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

    def kill!(machines,options={:providers=>:all})
      providers = options[:providers]
      if providers == :all or providers == :iaas
        delegate_to(all_iaas) { destroy! machines }
      end
      if providers == :all or providers == :chef
        delegate_to(chef) { destroy! machines }
      end
    end

    def launch!(machines)
      delegate_to(all_providers) { create_dependencies! machines }
      delegate_to(all_iaas) { create_instances! machines }
      sync! machines
    end

    def stop!(machines)
      delegate_to(all_iaas) { stop_instances! machines }
      sync! machines, :providers => :chef
    end

    def start!(machines)
      delegate_to(all_providers) { create_dependencies! machines }
#      sync! machines, :providers => :chef
      delegate_to(all_iaas) { start_instances! machines }
      sync! machines
    end

    # Save chef last, to ensure all other providers have recorded
    #   their values into the attributes appropriately
    def sync!(machines,options={:providers => :all})
      providers = options[:providers]
      if providers == :all or providers == :iaas
        delegate_to(all_iaas) { save! machines }
      end
      if providers == :all or providers == :chef
        delegate_to(chef) { save! machines }
      end
    end

    #
    #   PERSONAL METHODS
    #

    def all_providers() [chef, all_iaas].flatten;       end
    def all_iaas()      providers.values;               end
  end

end