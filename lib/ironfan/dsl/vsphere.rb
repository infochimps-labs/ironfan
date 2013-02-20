module Ironfan
  class Dsl

    class Compute < Ironfan::Dsl
      def vsphere(*attrs,&block)
        cloud(:vsphere, *attrs,&block)
      end
    end

    class Vsphere < Cloud
      magic :provider,                  Whatever,       :default => Ironfan::Provider::Vsphere

      def implied_volumes
        results = []
        return results
      end

      def to_display(style,values={})
        return values if style == :minimal

#        values["Flavor"] =            flavor
#       values["AZ"] =                default_availability_zone
        return values if style == :default

#       values["Public IP"] =        elastic_ip if elastic_ip
        values
      end

    end
  end
end
