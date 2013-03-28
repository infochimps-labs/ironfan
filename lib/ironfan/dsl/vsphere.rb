module Ironfan
  class Dsl

    class Compute < Ironfan::Dsl
      def vsphere(*attrs,&block)
        cloud(:vsphere, *attrs,&block)
      end
    end

    class Vsphere < Cloud
      magic :backing,                   String,         :default => ''
      magic :bits,                      Integer,        :default => "64"
      magic :bootstrap_distro,          String,         :default => 'ubuntu12.04-gems'
      magic :chef_client_script,        String
      magic :cluster,                   String
      magic :cpus,                      String,         :default => "1" 
      magic :datacenter,                String,         :default => ->{ default_datacenter }
      magic :datastore,                 String
      magic :dns_servers,		Array
      magic :domain,                    String 
      magic :default_datacenter,        String,         :default => ->{ vsphere_datacenters.first }
      magic :image_name,                String
      magic :ip, 	                String
      magic :memory,                    String,         :default => "4" # Gigabytes
      magic :provider,                  Whatever,       :default => Ironfan::Provider::Vsphere
      magic :ssh_identity_dir,          String,         :default => ->{ Chef::Config.vsphere_key_dir }
      magic :ssh_user,                  String,         :default => "root"
      magic :subnet,			String
      magic :template,                  String
      magic :validation_key,            String,         :default => ->{ IO.read(Chef::Config.validation_key) rescue '' }
      magic :virtual_disks,             Array,          :default => []
      magic :vsphere_datacenters,       Array,          :default => ['New Datacenter']
      magic :network, 			String,		:default => "VM Network"

      def image_info
        bit_str = "#{self.bits.to_i}-bit" # correct for legacy image info.
        keys = [datacenter, bit_str, image_name]
#        info = Chef::Config[:vsphere_image_info][ keys ]
        info = nil
        ui.warn("Can't find image for #{[datacenter, bit_str, image_name].inspect}") if info.blank?
        return info || {}
      end

      def implied_volumes
        result = []
        # FIXME : This is really making assumptions
        result << Ironfan::Dsl::Volume.new(:name => 'root') do
            device              '/dev/sda1'
            fstype              'ext4'
            keep                false
            mount_point         '/'
        end
        return result unless virtual_disks.length > 0

        virtual_disks.each_with_index do |vd, idx|
          dev, mnt = ["/dev/sd%s" %[(66 + idx).chr.downcase], idx == 0 ? "/mnt" : "/mnt#{idx}"] # WHAAAaaa 0 o ??? 
          virtualdisk = Ironfan::Dsl::Volume.new(:name => "virtualdisk#{idx}") do
            attachable          "VirtualDisk"
            fstype              vd[:fs]
            device              dev
            mount_point         vd[:mount_point] || mnt
            formattable         true
            create_at_launch    true
            mount_options       'defaults,noatime'
            tags                vd[:tags] 
          end
          result << virtualdisk
        end
        result
      end

      def ssh_identity_file(computer)
        cluster = computer.server.cluster_name
        "%s/%s.pem" %[ssh_identity_dir, cluster]
      end

      def to_display(style,values={})
        return values if style == :minimal

        values["Datacenter"] =         datacenter
        return values if style == :default

        values
      end

    end
  end
end
