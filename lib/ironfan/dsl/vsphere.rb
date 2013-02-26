module Ironfan
  class Dsl

    class Compute < Ironfan::Dsl
      def vsphere(*attrs,&block)
        cloud(:vsphere, *attrs,&block)
      end
    end

    class Vsphere < Cloud
      magic :provider,                  Whatever,       :default => Ironfan::Provider::Vsphere
      magic :vsphere_datacenters,       Array,          :default => ['New Datacenter']
      magic :default_datacenter,        String,         :default => ->{ vsphere_datacenters.first }
      magic :template_directory,        String

      def implied_volumes
        results = []
        return results
      end

      def to_display(style,values={})
        return values if style == :minimal

#        values["Flavor"] =            flavor
        values["Datacenter"] =         default_datacenter
        return values if style == :default
        values
      end

    end
  end
end
