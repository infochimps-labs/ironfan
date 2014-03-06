module Ironfan
  class Dsl

    class Compute < Ironfan::Dsl
      def autoscale(*attrs,&bloCK)      cloud(:autoscale,*attrs,&block);      end
    end

    class Autoscale < Cloud
      magic :availability_zones,        Array,          :default => ['us-east-1d']
      magic :backing,                   String,         :default => 'ebs'
      magic :bits,                      Integer,        :default => ->{ flavor_info[:bits] }
      magic :bootstrap_distro,          String,         :default => ->{ image_info[:bootstrap_distro] }
      magic :chef_client_script,        String
      magic :default_availability_zone, String,         :default => ->{ availability_zones.first }
      magic :default_cooldown,          Integer
      magic :desired_capacity,          Integer,        :default => -> { min_size }
      magic :flavor,                    String,         :default => 't1.micro'
      magic :health_check_grace_period, Integer
      magic :health_check_type,         String
      magic :image_id,                  String,         :default => -> { image_info[:image_id] }
      magic :image_name,                String
      magic :kernel_id,                 String
      magic :keypair,                   String
      magic :min_size,                  Integer,        :default => 0
      magic :max_size,                  Integer,        :default => 0
      # magic :monitoring,                :boolean    # TODO: fix support for monitoring
      magic :mount_ephemerals,          Hash,           :default => {}
      magic :placement_group,           String
      magic :provider,                  Whatever,       :default => Ironfan::Provider::Autoscale
      magic :ramdisk_id,                String
      magic :region,                    String,         :default => ->{ default_region }
      collection :security_groups,      Ironfan::Dsl::Ec2::SecurityGroup, :key_method => :name
      magic :subnet,                    String
      magic :spot_price,                String  # TODO: option is unsupported by fog
      magic :termination_policies,      Array

      module DisplayHelper
        # Format ['us-east-1c', 'us-east-1b'] as 'us-east-1c/b'
        def displayable_availability_zones
          zones = availability_zones.map{ |s| s[-1] } # last character of each zone
          region = availability_zones.first[0..-2]    # all but the last character of the first zone
          region + zones.join('/')
        end
      end
      include DisplayHelper

      def image_info
        bit_str = "#{self.bits.to_i}-bit" # correct for legacy image info.
        keys = [region, bit_str, backing, image_name]
        info = Chef::Config[:ec2_image_info][ keys ]
        ui.warn("Can't find image for #{[region, bit_str, backing, image_name].inspect}") if info.blank?
        return info || {}
      end

      def flavor_info
        if not Chef::Config[:ec2_flavor_info].has_key?(flavor)
          ui.warn("Unknown machine image flavor '#{flavor}'")
          list_flavors
          return nil
        end
        Chef::Config[:ec2_flavor_info][flavor]
      end

      def default_region
        default_availability_zone ? default_availability_zone.gsub(/^(\w+-\w+-\d)[a-z]/, '\1') : nil
      end

      def to_display(style,values={})
        return values if style == :minimal

        values["Flavor"] =            flavor
        values["AZ"] =                displayable_availability_zones
        return values if style == :default

        values
      end

      def implied_volumes
        result = []
      end

    end

  end
end
