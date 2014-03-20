require 'digest/md5'

module Ironfan
  class Dsl

    class Compute < Ironfan::Dsl
      def openstack(*attrs,&block)            cloud(:openstack,*attrs,&block);      end
    end

    class OpenStack < Cloud
      magic :availability_zones,        Array,          :default => ['nova']
      magic :backing,                   String,         :default => 'ebs'
      magic :bits,                      Integer,        :default => ->{ flavor_info[:bits] }
      magic :bootstrap_distro,          String,         :default => ->{ image_info[:bootstrap_distro] }
      magic :chef_client_script,        String
      magic :default_availability_zone, String,         :default => ->{ availability_zones.first }
      #collection :elastic_load_balancers,  Ironfan::Dsl::Ec2::ElasticLoadBalancer, :key_method => :name
      magic :ebs_optimized,             :boolean,       :default => false
      magic :flavor,                    String,         :default => 't1.micro'
      #collection :iam_server_certificates, Ironfan::Dsl::Ec2::IamServerCertificate, :key_method => :name
      magic :image_id,                  String
      magic :image_name,                String
      magic :keypair,                   String
      magic :monitoring,                String
      magic :mount_ephemerals,          Hash,           :default => {}
      magic :permanent,                 :boolean,       :default => false
      magic :placement_group,           String
      magic :provider,                  Whatever,       :default => Ironfan::Provider::OpenStack
      magic :elastic_ip,                String
      magic :auto_elastic_ip,           String
      magic :allocation_id,             String
      magic :region,                    String,         :default => ->{ default_region }
      collection :security_groups,      Ironfan::Dsl::SecurityGroup, :key_method => :name
      magic :ssh_user,                  String,         :default => ->{ image_info[:ssh_user] }
      magic :ssh_identity_dir,          String,         :default => ->{ Chef::Config.openstack_key_dir }
      magic :subnet,                    String
      magic :validation_key,            String,         :default => ->{ IO.read(Chef::Config.validation_key) rescue '' }
      magic :vpc,                       String
      magic :dns_search_domain,         String,         :default => 'novalocal'

      def domain;                       vpc.nil? ? 'standard' : 'vpc';       end

      def image_info
        bit_str = "#{self.bits.to_i}-bit" # correct for legacy image info.
        keys = [region, bit_str, backing, image_name]
        info = Chef::Config[:openstack_image_info][ keys ]
        ui.warn("Can't find image for #{[region, bit_str, backing, image_name].inspect}") if info.blank?
        return info || {}
      end

      def image_id
        result = read_attribute(:image_id) || image_info[:image_id]
      end

      def ssh_key_name(computer)
        keypair ? keypair.to_s : computer.server.keypair_name
      end

      def default_region
        default_availability_zone ? default_availability_zone.gsub(/^(\w+-\w+-\d)[a-z]/, '\1') : nil
      end

      def to_display(style,values={})
        return values if style == :minimal

        values["Flavor"] =            flavor
        values["AZ"] =                default_availability_zone
        return values if style == :default

        values["Public IP"] =        elastic_ip if elastic_ip
        values
      end

      def flavor_info
        if not Chef::Config[:openstack_flavor_info].has_key?(flavor)
          ui.warn("Unknown machine image flavor '#{flavor}'")
          list_flavors
          return nil
        end
        Chef::Config[:openstack_flavor_info][flavor]
      end

      def implied_volumes
        result = []
        if backing == 'ebs'
          result << Ironfan::Dsl::Volume.new(:name => 'root') do
            device              '/dev/sda1'
            fstype              'ext4'
            keep                false
            mount_point         '/'
          end
        end
        return result unless (mount_ephemerals and (flavor_info[:ephemeral_volumes] > 0))

        layout = {  0 => ['/dev/sdb','/mnt'],
                    1 => ['/dev/sdc','/mnt2'],
                    2 => ['/dev/sdd','/mnt3'],
                    3 => ['/dev/sde','/mnt4']   }
        ( 0 .. (flavor_info[:ephemeral_volumes]-1) ).each do |idx|
          dev, mnt = layout[idx]
          ephemeral = Ironfan::Dsl::Volume.new(:name => "ephemeral#{idx}") do
            attachable          'ephemeral'
            fstype              'ext3'
            device              dev
            mount_point         mnt
            mount_options       'defaults,noatime'
            tags({:bulk => true, :local => true, :fallback => true})
          end
          ephemeral_attrs = mount_ephemerals.clone
          if ephemeral_attrs.has_key?(:disks)
            disk_attrs = mount_ephemerals[:disks][idx] || { }
            ephemeral_attrs.delete(:disks)
            ephemeral_attrs.merge!(disk_attrs)
          end
          ephemeral.receive! ephemeral_attrs
          result << ephemeral
        end
        result
      end

      def receive_provider(obj)
        if obj.is_a?(String)
          write_attribute :provider, Gorillib::Inflector.constantize(Gorillib::Inflector.camelize(obj.gsub(/\./, '/')))
        else
          super(obj)
        end
      end
    end
  end
end

Chef::Config[:openstack_flavor_info] ||= {}
Chef::Config[:openstack_flavor_info].merge!({
    # 32-or-64: m1.small, m1.medium, t1.micro, c1.medium
    't1.micro'    => { :price => 0.02,  :bits => 64, :ram =>    686, :cores => 1, :core_size => 0.25, :inst_disks => 0, :inst_disk_size =>    0, :ephemeral_volumes => 0 },
    'm1.small'    => { :price => 0.08,  :bits => 64, :ram =>   1740, :cores => 1, :core_size => 1,    :inst_disks => 1, :inst_disk_size =>  160, :ephemeral_volumes => 1 },
    'm1.medium'   => { :price => 0.165, :bits => 64, :ram =>   3840, :cores => 2, :core_size => 1,    :inst_disks => 1, :inst_disk_size =>  410, :ephemeral_volumes => 1 },
    'c1.medium'   => { :price => 0.17,  :bits => 64, :ram =>   1740, :cores => 2, :core_size => 2.5,  :inst_disks => 1, :inst_disk_size =>  350, :ephemeral_volumes => 1 },
    #
    'm1.large'    => { :price => 0.32,  :bits => 64, :ram =>   7680, :cores => 2, :core_size => 2,    :inst_disks => 1, :inst_disk_size =>  850, :ephemeral_volumes => 2, },
    'm2.xlarge'   => { :price => 0.45,  :bits => 64, :ram =>  18124, :cores => 2, :core_size => 3.25, :inst_disks => 1, :inst_disk_size =>  420, :ephemeral_volumes => 1, },
    'c1.xlarge'   => { :price => 0.64,  :bits => 64, :ram =>   7168, :cores => 8, :core_size => 2.5,  :inst_disks => 1, :inst_disk_size => 1690, :ephemeral_volumes => 4, },
    'm1.xlarge'   => { :price => 0.66,  :bits => 64, :ram =>  15360, :cores => 4, :core_size => 2,    :inst_disks => 1, :inst_disk_size => 1690, :ephemeral_volumes => 4, },
  })

Chef::Config[:openstack_image_info] ||= {}

