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
      magic :image_name,                String
      magic :bits,                      Integer,        :default => "64"
      magic :ssh_user,                  String,         :default => ->{ image_info[:ssh_user] }
      magic :ssh_identity_dir,          String,         :default => ->{ Chef::Config.vsphere_key_dir }
      magic :bootstrap_distro,          String,         :default => 'ubuntu12.04-gems'
      magic :validation_key,            String,         :default => ->{ IO.read(Chef::Config.validation_key) rescue '' }
      magic :datacenter,                String,         :default => ->{ default_datacenter }
      

      def image_info
        bit_str = "#{self.bits.to_i}-bit" # correct for legacy image info.
        keys = [datacenter, bit_str, image_name]
#        info = Chef::Config[:vsphere_image_info][ keys ]
        info = nil
        ui.warn("Can't find image for #{[datacenter, bit_str, image_name].inspect}") if info.blank?
        return info || {}
      end

      def implied_volumes
        results = []
        return results
      end

      def ssh_identity_file(computer)
        cluster = computer.server.cluster_name
        "%s/%s" %[ssh_identity_dir, cluster]
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

Chef::Config[:vsphere_vm_info] ||= {}
Chef::Config[:vsphere_vm_info].merge!({
  #
  # Presice (Ubuntu 12.04)
  #
  %w["New Datacenter" 64-bit presice] => { :template_name => 'Ubuntu 12.04 Template2', :ssh_user => 'root', :bootstrap_distro => "ubuntu10.04-gems", }})
