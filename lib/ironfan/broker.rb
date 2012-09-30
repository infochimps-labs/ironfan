# This module is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers, to control instance life-cycle and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for
#   them.
module Ironfan
  def self.broker
    @@broker ||= Ironfan::Broker.new
  end

  class Broker < Builder
    # Take in a Dsl::Cluster; return Computers populated with all discovered
    #   resources that correlate; computers corresponding to partial or
    #   unrecognizable resources are labeled as bogus.
    def discover!(cluster)
      # Get fully resolved servers, and build Computers using them
      computers = Computers.new(:cluster => cluster)
      #
      providers = computers.map{|c| c.providers.values }.flatten.uniq
      Ironfan.parallel(providers) do |provider|
        Ironfan.step cluster.name, "Loading #{provider.handle}", :cyan
        provider.load cluster
      end
      #
      Ironfan.step cluster.name, "Reconciling DSL and provider information", :cyan
      computers.correlate
      computers.validate
      #
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

  end
end
