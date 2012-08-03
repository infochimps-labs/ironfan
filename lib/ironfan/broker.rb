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

    # Take in a Dsl::Cluster, return Computers populated with
    #   all discovered resources that correlate, plus bogus computers
    #   corresponding to 
    def discover!(cluster)
      # Get fully resolved servers, and build Computers using them
      computers = Computers.new(:cluster => cluster.resolve)
      # ensure that each chosen provider is available
      computers.each {|m| provider(m.server.selected_cloud.name) }

      delegate_to(all_providers) do
        load! computers
        correlate! computers
      end
      delegate_to(all_providers) { validate! computers }
      computers
    end

    def display(computers,style)
      defined_data = computers.map {|m| m.to_display(style) }
      if defined_data.empty?
        ui.info "Nothing to report"
      else
        headings = defined_data.map{|r| r.keys}.flatten.uniq
        Formatador.display_compact_table(defined_data, headings.to_a)
      end
    end

    def kill!(computers,options={})
      delegate_to_chosen_providers(options) { destroy_machines! computers }
    end

    def launch!(computers)
      delegate_to(all_providers) { ensure_prerequisites! computers }
      delegate_to(all_iaas) { create_machines! computers }
      sync! computers
    end

    def stop!(computers)
      delegate_to(all_iaas) { stop_machines! computers }
      sync! computers, :providers => :chef
    end

    def start!(computers)
      delegate_to(all_providers) { ensure_prerequisites! computers }
      delegate_to(all_iaas) { start_machines! computers }
      sync! computers
    end

    def sync!(computers,options={})
      delegate_to_chosen_providers(options) { save! computers }
    end

    #
    #   PERSONAL METHODS
    #

    def all_providers() [chef, all_iaas].flatten;       end
    def all_iaas()      providers.values;               end
    # Target chef last, to ensure all other providers have recorded
    #   their values into the attributes appropriately
    def delegate_to_chosen_providers(options={:providers => :all},&block)
      case options[:providers]
      when :all
        delegate_to all_iaas, &block
        delegate_to chef, &block
      when :iaas      then all_iaas
        delegate_to all_iaas, &block
      when :chef      then chef
        delegate_to chef, &block
      end
    end
  end

end