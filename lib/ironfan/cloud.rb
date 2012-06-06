module Ironfan
  module Cloud

    #
    # Right now only one cloud provider is implemented, so the separation
    # between `cloud` and `cloud(:ec2)` is muddy.
    #
    # The goal though is to allow
    #
    # * cloud with no predicate -- definitions that apply to all cloud
    #   providers. If you only use one provider ever nothing stops you from
    #   always saying `cloud`.
    # * Declarations irrelevant to other providers are acceptable and will be ignored
    # * Declarations that are wrong in the context of other providers (a `public_ip`
    #   that is not available) will presumably cause a downstream error -- it's
    #   your responsibility to overlay with provider-correct values.
    # * There are several declarations that *could* be sensibly abstracted, but
    #   are not. Rather than specifying `flavor 'm1.xlarge'`, I could ask for
    #   :ram => 15, :cores => 4 or storage => 1500 and get the cheapest machine
    #   that met or exceeded each constraint -- the default of `:price =>
    #   :smallest` would get me a t1.micro on EC2, a 256MB on
    #   Rackspace. Availability zones could also plausibly be parameterized.
    #
    # @example
    #     # these apply regardless of cloud provider
    #     cloud do
    #       # this makes sense everywhere
    #       image_name            'maverick'
    #
    #       # this is not offered by many providers, and its value is non-portable;
    #       # but if you only run in one cloud there's harm in putting it here
    #       # or overriding it.
    #       public_ip             '1.2.3.4'
    #
    #       # Implemented differently across providers but its meaning is clear
    #       security_group        :nagios
    #
    #       # This is harmless for the other clouds
    #       availability_zones   ['us-east-1d']
    #     end
    #
    #     # these only apply to ec2 launches.
    #     # `ec2` is sugar for `cloud(:ec2)`.
    #     ec2 do
    #       spot_price_fraction   0.4
    #     end
    #
    class Base < Ironfan::DslObject
      has_keys(
        :name, :flavor, :image_name, :image_id, :keypair,
        :chef_client_script, :public_ip, :permanent )
      attr_accessor :owner

      def initialize(owner, *args)
        self.owner = owner
        super(*args)
      end

      # default values to apply where no value was set
      # @return [Hash] hash of defaults
      def defaults
        reverse_merge!({
          :image_name         => 'natty',
        })
      end

      # The username to ssh with.
      # @return the ssh_user if set explicitly; otherwise, the user implied by the image name, if any; or else 'root'
      def ssh_user(val=nil)
        from_setting_or_image_info :ssh_user, val, 'root'
      end

      # Location of ssh private keys
      def ssh_identity_dir(val=nil)
        set :ssh_identity_dir, File.expand_path(val) unless val.nil?
        @settings.include?(:ssh_identity_dir) ? @settings[:ssh_identity_dir] : Chef::Config.ec2_key_dir
      end

      # SSH identity file used for knife ssh, knife boostrap and such
      def ssh_identity_file(val=nil)
        set :ssh_identity_file, File.expand_path(val) unless val.nil?
        @settings.include?(:ssh_identity_file) ? @settings[:ssh_identity_file] : File.join(ssh_identity_dir, "#{keypair}.pem")
      end

      # ID of the machine image to use.
      # @return the image_id if set explicitly; otherwise, the id implied by the image name
      def image_id(val=nil)
        from_setting_or_image_info :image_id, val
      end

      # Distribution knife should target when bootstrapping an instance
      # @return the bootstrap_distro if set explicitly; otherwise, the bootstrap_distro implied by the image name
      def bootstrap_distro(val=nil)
        from_setting_or_image_info :bootstrap_distro, val, "ubuntu10.04-gems"
      end

      def validation_key
        IO.read(Chef::Config.validation_key) rescue ''
      end

      # The instance price, drawn from the compute flavor's info
      def price
        flavor_info[:price]
      end

      # The instance bitness, drawn from the compute flavor's info
      def bits
        flavor_info[:bits]
      end

    protected
      # If value was explicitly set, use that; if the Chef::Config[:ec2_image_info] implies a value use that; otherwise use the default
      def from_setting_or_image_info(key, val=nil, default=nil)
        @settings[key] = val unless val.nil?
        return @settings[key]  if @settings.include?(key)
#         return image_info[key] unless image_info.nil?
        return default       # otherwise
      end
    end

    class Ec2 < Base
      has_keys(
        :region, :availability_zones, :backing,
        :spot_price, :spot_price_fraction,
        :user_data, :security_groups,
        :monitoring, :placement_group,
        :vpc, :subnet
        )

      def initialize(*args)
        super *args
        name :ec2 # cloud provider name
        @settings[:security_groups]      ||= Mash.new
        @settings[:user_data]            ||= Mash.new
      end

      #
      # Sets some defaults for amazon cloud usage, and registers the root volume
      #
      def defaults
        owner.volume(:root).reverse_merge!({
            :device      => '/dev/sda1',
            :mount_point => '/',
            :mountable   => false,
          })
        self.reverse_merge!({
            :availability_zones => ['us-east-1d'],
            :backing            => 'ebs',
            :flavor             => 't1.micro',
          })
        super
      end

      # adds a security group to the cloud instance
      def security_group(sg_name, hsh={}, &block)
        sg_name = sg_name.to_s
        security_groups[sg_name] ||= Ironfan::Cloud::SecurityGroup.new(self, sg_name)
        security_groups[sg_name].configure(hsh, &block)
        security_groups[sg_name]
      end

      # With a value, sets the spot price to the given fraction of the
      #   instance's full price (as found in Ironfan::Cloud::Aws::FLAVOR_INFO)
      # With no value, returns the spot price as a fraction of the full instance price.
      def spot_price_fraction(val=nil)
        if val
          spot_price( price.to_f * val )
        else
          spot_price / price rescue 0
        end
      end

      # EC2 User data -- DNA typically used to bootstrap the machine.
      # @param  [Hash] value -- when present, merged with the existing user data (overriding it)
      # @return the user_data hash
      def user_data(hsh={})
        @settings[:user_data].merge!(hsh.to_hash) unless hsh.empty?
        @settings[:user_data]
      end

      def reverse_merge!(hsh)
        super(hsh.to_mash.compact)
        @settings[:security_groups].reverse_merge!(hsh.security_groups) if hsh.respond_to?(:security_groups)
        @settings[:user_data      ].reverse_merge!(hsh.user_data)       if hsh.respond_to?(:user_data)
        self
      end

      def region(val=nil)
        set(:region, val)
        if    @settings[:region]        then @settings[:region]
        elsif default_availability_zone then default_availability_zone.gsub(/^(\w+-\w+-\d)[a-z]/, '\1')
        else  nil
        end
      end

      def placement_group(val=nil)
        set(:placement_group, val)
        @settings[:placement_group] || owner.cluster_name
      end

      def default_availability_zone
        availability_zones.first if availability_zones
      end

      # Bring the ephemeral storage (local scratch disks) online
      def mount_ephemerals(attrs={})
        owner.volume(:ephemeral0, attrs){ device '/dev/sdb'; volume_id 'ephemeral0' ; mount_point '/mnt' ; tags( :bulk => true, :local => true, :fallback => true) } if flavor_info[:ephemeral_volumes] > 0
        owner.volume(:ephemeral1, attrs){ device '/dev/sdc'; volume_id 'ephemeral1' ; mount_point '/mnt2'; tags( :bulk => true, :local => true, :fallback => true) } if flavor_info[:ephemeral_volumes] > 1
        owner.volume(:ephemeral2, attrs){ device '/dev/sdd'; volume_id 'ephemeral2' ; mount_point '/mnt3'; tags( :bulk => true, :local => true, :fallback => true) } if flavor_info[:ephemeral_volumes] > 2
        owner.volume(:ephemeral3, attrs){ device '/dev/sde'; volume_id 'ephemeral3' ; mount_point '/mnt4'; tags( :bulk => true, :local => true, :fallback => true) } if flavor_info[:ephemeral_volumes] > 3
      end

      # Utility methods

      require 'pry'

      def image_info
        ec2_image_info[ [region, bits, backing, image_name] ] or ( ui.warn "Make sure to define the machine's region, bits, backing and image_name. (Have #{[region, bits, backing, image_name, virtualization].inspect})" ; {} )
      end

      def ec2_image_info
        return @image_info_mapping if @image_info_mapping
        @image_info_mapping = Chef::Config[:ec2_image_info]
        # @image_info_mapping.each{|key, val| key[4] ||= 'pv' }
        @image_info_mapping
      end

      def virtualization
        flavor_info[:virtualization] || 'pv'
      end

      def list_images
        ui.info("Available images:")
        ec2_image_info.each do |flavor_name, flavor|
          ui.info("  %-55s\t%s" % [flavor_name, flavor.inspect])
        end
      end

      def vpc(val=nil)
        set :vpc, val
      end

      def subnet(val=nil)
        set :subnet, val
      end

      def flavor(val=nil)
        if val && (not FLAVOR_INFO.has_key?(val.to_s))
          ui.warn("Unknown machine image flavor '#{val}'")
          list_flavors
        end
        set :flavor, val
      end

      def flavor_info
        FLAVOR_INFO[flavor] or ( ui.warn "Please define the machine's flavor: have #{self.inspect}" ; {} )
      end

      def list_flavors
        ui.info("Available flavors:")
        FLAVOR_INFO.each do |flavor_name, flavor|
          ui.info("  #{flavor_name}\t#{flavor.inspect}")
        end
      end

      # code            $/mo     $/day   $/hr   CPU/$   Mem/$     mem     cpu   cores   cpcore  storage bits    IO              type            name
      # t1.micro          15      0.48    .02      13      13     0.61    0.25   0.25     1           0    32   Low             Micro           Micro
      # m1.small          58      1.92    .08      13      21     1.7     1      1        1         160    32   Moderate        Standard        Small
      # m1.medium        116      3.84    .165     13      13     3.75    2      2        1         410    32   Moderate        Standard        Medium
      # c1.medium        120      3.96    .17      30      10     1.7     5      2        2.5       350    32   Moderate        High-CPU        Medium
      # m1.large         232      7.68    .32      13      23     7.5     4      2        2         850    64   High            Standard        Large
      # m2.xlarge        327     10.80    .45      14      38    17.1     6.5    2        3.25      420    64   Moderate        High-Memory     Extra Large
      # m1.xlarge        465     15.36    .64      13      23    15       8      4        2        1690    64   High            Standard        Extra Large
      # c1.xlarge        479     15.84    .66      30      11     7      20      8        2.5      1690    64   High            High-CPU        Extra Large
      # m2.2xlarge       653     21.60    .90      14      38    34.2    13      4        3.25      850    64   High            High-Memory     Double Extra Large
      # m2.4xlarge      1307     43.20   1.80      14      38    68.4    26      8        3.25     1690    64   High            High-Memory     Quadruple Extra Large
      # cc1.4xlarge      944     31.20   1.30      26      18    23      33.5    8        4.19     1690    64   10GB            Compute         Quadruple Extra Large
      # cc2.8xlarge     1742     57.60   2.40      37      25    60.5    88     16        5.50     3370    64   Very High 10GB  Compute         Eight Extra Large
      # cg1.4xlarge     1525     50.40   2.10      16      10    22      33.5    8        4.19     1690    64   Very High 10GB  Cluster GPU     Quadruple Extra Large

      FLAVOR_INFO = {
        't1.micro'    => { :price => 0.02,  :bits => '64-bit', :ram =>    686, :cores => 1, :core_size => 0.25, :inst_disks => 0, :inst_disk_size =>    0, :ephemeral_volumes => 0 },
        'm1.small'    => { :price => 0.08,  :bits => '64-bit', :ram =>   1740, :cores => 1, :core_size => 1,    :inst_disks => 1, :inst_disk_size =>  160, :ephemeral_volumes => 1 },
        'm1.medium'   => { :price => 0.165, :bits => '32-bit', :ram =>   3840, :cores => 2, :core_size => 1,    :inst_disks => 1, :inst_disk_size =>  410, :ephemeral_volumes => 1 },
        'c1.medium'   => { :price => 0.17,  :bits => '32-bit', :ram =>   1740, :cores => 2, :core_size => 2.5,  :inst_disks => 1, :inst_disk_size =>  350, :ephemeral_volumes => 1 },
        'm1.large'    => { :price => 0.32,  :bits => '64-bit', :ram =>   7680, :cores => 2, :core_size => 2,    :inst_disks => 2, :inst_disk_size =>  850, :ephemeral_volumes => 2 },
        'm2.xlarge'   => { :price => 0.45,  :bits => '64-bit', :ram =>  18124, :cores => 2, :core_size => 3.25, :inst_disks => 1, :inst_disk_size =>  420, :ephemeral_volumes => 1 },
        'c1.xlarge'   => { :price => 0.64,  :bits => '64-bit', :ram =>   7168, :cores => 8, :core_size => 2.5,  :inst_disks => 4, :inst_disk_size => 1690, :ephemeral_volumes => 4 },
        'm1.xlarge'   => { :price => 0.66,  :bits => '64-bit', :ram =>  15360, :cores => 4, :core_size => 2,    :inst_disks => 4, :inst_disk_size => 1690, :ephemeral_volumes => 4 },
        'm2.2xlarge'  => { :price => 0.90,  :bits => '64-bit', :ram =>  35020, :cores => 4, :core_size => 3.25, :inst_disks => 2, :inst_disk_size =>  850, :ephemeral_volumes => 2 },
        'm2.4xlarge'  => { :price => 1.80,  :bits => '64-bit', :ram =>  70041, :cores => 8, :core_size => 3.25, :inst_disks => 4, :inst_disk_size => 1690, :ephemeral_volumes => 4 },
        'cc1.4xlarge' => { :price => 1.30,  :bits => '64-bit', :ram =>  23552, :cores => 8, :core_size => 4.19, :inst_disks => 4, :inst_disk_size => 1690, :ephemeral_volumes => 2, :placement_groupable => true, :virtualization => 'hvm' },
        'cc1.8xlarge' => { :price => 2.40,  :bits => '64-bit', :ram =>  61952, :cores =>16, :core_size => 5.50, :inst_disks => 8, :inst_disk_size => 3370, :ephemeral_volumes => 4, :placement_groupable => true, :virtualization => 'hvm' },
        'cg1.4xlarge' => { :price => 2.10,  :bits => '64-bit', :ram =>  22528, :cores => 8, :core_size => 4.19, :inst_disks => 4, :inst_disk_size => 1690, :ephemeral_volumes => 2, :placement_groupable => true, :virtualization => 'hvm' },
      }

      #
      # To add to this list, use this snippet:
      #
      #     Chef::Config[:ec2_image_info] ||= {}
      #     Chef::Config[:ec2_image_info].merge!({
      #       # ... lines like the below
      #     })
      #
      # in your knife.rb or whereever. We'll notice that it exists and add to it, rather than clobbering it.
      #
      Chef::Config[:ec2_image_info] ||= {}
      Chef::Config[:ec2_image_info].merge!({

          #
          # Lucid (Ubuntu 9.10)
          #
          %w[us-east-1             64-bit  instance        karmic     ] => { :image_id => 'ami-55739e3c', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[us-east-1             32-bit  instance        karmic     ] => { :image_id => 'ami-bb709dd2', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[us-west-1             64-bit  instance        karmic     ] => { :image_id => 'ami-cb2e7f8e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[us-west-1             32-bit  instance        karmic     ] => { :image_id => 'ami-c32e7f86', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[eu-west-1             64-bit  instance        karmic     ] => { :image_id => 'ami-05c2e971', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[eu-west-1             32-bit  instance        karmic     ] => { :image_id => 'ami-2fc2e95b', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

          #
          # Lucid (Ubuntu 10.04.3)
          #
          %w[ap-southeast-1        64-bit  ebs             lucid      ] => { :image_id => 'ami-77f28d25', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ap-southeast-1        32-bit  ebs             lucid      ] => { :image_id => 'ami-4df28d1f', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ap-southeast-1        64-bit  instance        lucid      ] => { :image_id => 'ami-57f28d05', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ap-southeast-1        32-bit  instance        lucid      ] => { :image_id => 'ami-a5f38cf7', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[eu-west-1             64-bit  ebs             lucid      ] => { :image_id => 'ami-ab4d67df', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[eu-west-1             32-bit  ebs             lucid      ] => { :image_id => 'ami-a94d67dd', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[eu-west-1             64-bit  instance        lucid      ] => { :image_id => 'ami-a54d67d1', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[eu-west-1             32-bit  instance        lucid      ] => { :image_id => 'ami-cf4d67bb', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[us-east-1             64-bit  ebs             lucid      ] => { :image_id => 'ami-4b4ba522', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[us-east-1             32-bit  ebs             lucid      ] => { :image_id => 'ami-714ba518', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[us-east-1             64-bit  instance        lucid      ] => { :image_id => 'ami-fd4aa494', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[us-east-1             32-bit  instance        lucid      ] => { :image_id => 'ami-2d4aa444', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[us-west-1             64-bit  ebs             lucid      ] => { :image_id => 'ami-d197c694', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[us-west-1             32-bit  ebs             lucid      ] => { :image_id => 'ami-cb97c68e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[us-west-1             64-bit  instance        lucid      ] => { :image_id => 'ami-c997c68c', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[us-west-1             32-bit  instance        lucid      ] => { :image_id => 'ami-c597c680', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

          #
          # Maverick (Ubuntu 10.10)
          #
          %w[ ap-southeast-1       64-bit  ebs             maverick   ] => { :image_id => 'ami-32423c60', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-southeast-1       64-bit  instance        maverick   ] => { :image_id => 'ami-12423c40', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-southeast-1       32-bit  ebs             maverick   ] => { :image_id => 'ami-0c423c5e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-southeast-1       32-bit  instance        maverick   ] => { :image_id => 'ami-7c423c2e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ eu-west-1            64-bit  ebs             maverick   ] => { :image_id => 'ami-e59ca991', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ eu-west-1            64-bit  instance        maverick   ] => { :image_id => 'ami-1b9ca96f', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ eu-west-1            32-bit  ebs             maverick   ] => { :image_id => 'ami-fb9ca98f', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ eu-west-1            32-bit  instance        maverick   ] => { :image_id => 'ami-339ca947', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ us-east-1            64-bit  ebs             maverick   ] => { :image_id => 'ami-cef405a7', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-east-1            64-bit  instance        maverick   ] => { :image_id => 'ami-08f40561', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-east-1            32-bit  ebs             maverick   ] => { :image_id => 'ami-ccf405a5', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-east-1            32-bit  instance        maverick   ] => { :image_id => 'ami-a6f504cf', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ us-west-1            64-bit  ebs             maverick   ] => { :image_id => 'ami-af7e2eea', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-1            64-bit  instance        maverick   ] => { :image_id => 'ami-a17e2ee4', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-1            32-bit  ebs             maverick   ] => { :image_id => 'ami-ad7e2ee8', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-1            32-bit  instance        maverick   ] => { :image_id => 'ami-957e2ed0', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

          #
          # Natty (Ubuntu 11.04)
          #
          %w[ ap-northeast-1       32-bit  ebs             natty      ] => { :image_id => 'ami-00b10501', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-northeast-1       32-bit  instance        natty      ] => { :image_id => 'ami-f0b004f1', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-northeast-1       64-bit  ebs             natty      ] => { :image_id => 'ami-02b10503', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-northeast-1       64-bit  instance        natty      ] => { :image_id => 'ami-fab004fb', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ ap-southeast-1       32-bit  ebs             natty      ] => { :image_id => 'ami-06255f54', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-southeast-1       32-bit  instance        natty      ] => { :image_id => 'ami-72255f20', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-southeast-1       64-bit  ebs             natty      ] => { :image_id => 'ami-04255f56', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-southeast-1       64-bit  instance        natty      ] => { :image_id => 'ami-7a255f28', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ eu-west-1            32-bit  ebs             natty      ] => { :image_id => 'ami-a4f7c5d0', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ eu-west-1            32-bit  instance        natty      ] => { :image_id => 'ami-fef7c58a', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ eu-west-1            64-bit  ebs             natty      ] => { :image_id => 'ami-a6f7c5d2', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ eu-west-1            64-bit  instance        natty      ] => { :image_id => 'ami-c0f7c5b4', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ us-east-1            32-bit  ebs             natty      ] => { :image_id => 'ami-e358958a', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-east-1            32-bit  instance        natty      ] => { :image_id => 'ami-c15994a8', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-east-1            64-bit  ebs             natty      ] => { :image_id => 'ami-fd589594', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-east-1            64-bit  instance        natty      ] => { :image_id => 'ami-71589518', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ us-west-1            32-bit  ebs             natty      ] => { :image_id => 'ami-43580406', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-1            32-bit  instance        natty      ] => { :image_id => 'ami-e95f03ac', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-1            64-bit  ebs             natty      ] => { :image_id => 'ami-4d580408', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-1            64-bit  instance        natty      ] => { :image_id => 'ami-a15f03e4', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

          #
          # Cluster Compute
          #
          # IMAGE   ami-6d2ce204    205199409180/Globus Provision 0.4.AMI (Ubuntu 11.04 HVM)            205199409180    available       public          x86_64  machine                 ebs             hvm             xen
          #
          %w[ us-east-1            64-bit  ebs             natty-cc   ] => { :image_id => 'ami-6d2ce204', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

          #
          # Oneiric (Ubuntu 11.10)
          #
          %w[ ap-northeast-1       32-bit  ebs             oneiric    ] => { :image_id => 'ami-84902785', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-northeast-1       32-bit  instance        oneiric    ] => { :image_id => 'ami-5e90275f', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-northeast-1       64-bit  ebs             oneiric    ] => { :image_id => 'ami-88902789', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-northeast-1       64-bit  instance        oneiric    ] => { :image_id => 'ami-7c90277d', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ ap-southeast-1       32-bit  ebs             oneiric    ] => { :image_id => 'ami-0a327758', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-southeast-1       32-bit  instance        oneiric    ] => { :image_id => 'ami-00327752', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-southeast-1       64-bit  ebs             oneiric    ] => { :image_id => 'ami-0832775a', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ ap-southeast-1       64-bit  instance        oneiric    ] => { :image_id => 'ami-04327756', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ eu-west-1            32-bit  ebs             oneiric    ] => { :image_id => 'ami-11f0cc65', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ eu-west-1            32-bit  instance        oneiric    ] => { :image_id => 'ami-4ff0cc3b', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ eu-west-1            64-bit  ebs             oneiric    ] => { :image_id => 'ami-1df0cc69', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ eu-west-1            64-bit  instance        oneiric    ] => { :image_id => 'ami-23f0cc57', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ us-east-1            32-bit  ebs             oneiric    ] => { :image_id => 'ami-a562a9cc', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-east-1            32-bit  instance        oneiric    ] => { :image_id => 'ami-3962a950', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-east-1            64-bit  ebs             oneiric    ] => { :image_id => 'ami-bf62a9d6', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-east-1            64-bit  instance        oneiric    ] => { :image_id => 'ami-c162a9a8', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ us-west-1            32-bit  ebs             oneiric    ] => { :image_id => 'ami-c9a1fe8c', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-1            32-bit  instance        oneiric    ] => { :image_id => 'ami-21a1fe64', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-1            64-bit  ebs             oneiric    ] => { :image_id => 'ami-cba1fe8e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-1            64-bit  instance        oneiric    ] => { :image_id => 'ami-3fa1fe7a', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          #
          %w[ us-west-2            32-bit  ebs             oneiric    ] => { :image_id => 'ami-ea9a17da', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-2            32-bit  instance        oneiric    ] => { :image_id => 'ami-f49a17c4', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-2            64-bit  ebs             oneiric    ] => { :image_id => 'ami-ec9a17dc', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ us-west-2            64-bit  instance        oneiric    ] => { :image_id => 'ami-fe9a17ce', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        })
    end

    class Slicehost < Base
      # server_name
      # slicehost_password
      # Proc.new { |password| Chef::Config[:knife][:slicehost_password] = password }

      # personality
    end

    class Rackspace < Base
      # api_key, api_username, server_name
    end

    class Terremark < Base
      # password, username, service
    end

    class Physical < Base
      def target_address(val=nil)
        from_setting_or_image_info :target_address, val
      end
      def target_password(val=nil)
        from_setting_or_image_info :target_password, val
      end
      def target_user(val=nil)
        from_setting_or_image_info :target_user, val, 'ubuntu'
      end
      def target_port(val=nil)
        from_setting_or_image_info :target_port, val, 22
      end
      def user_data(val=nil)
        from_setting_or_image_info :user_data, val
      end
    end
  end
end
