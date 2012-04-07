module Ironfan
  module Cloud

    #
    # Right now only one cloud provider is implemented, so the separation
    # between `cloud` and `cloud(:`rackspace)` is muddy.
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
    #     # these only apply to `rackspace launches.
    #     # ``rackspace` is sugar for `cloud(:`rackspace)`.
    #     `rackspace do
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
        @settings.include?(:ssh_identity_dir) ? @settings[:ssh_identity_dir] : Chef::Config.rackspace_key_dir
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
      # If value was explicitly set, use that; if the Chef::Config[:rackspace_image_info] implies a value use that; otherwise use the default
      def from_setting_or_image_info(key, val=nil, default=nil)
        @settings[key] = val unless val.nil?
        return @settings[key]  if @settings.include?(key)
        return image_info[key] unless image_info.nil?
        return default       # otherwise
      end
    end

    class Ec2 < Base
    end

    class Slicehost < Base
      # server_name
      # slicehost_password
      # Proc.new { |password| Chef::Config[:knife][:slicehost_password] = password }

      # personality
    end

    class Rackspace < Base
      # api_key, api_username, server_name
      has_keys(
        :region, :availability_zones, :backing,
        :spot_price, :spot_price_fraction,
        :user_data, :security_groups,
        :monitoring
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
      #   instance's full price (as found in Ironfan::Cloud::Rackspace::FLAVOR_INFO)
      # With no value, returns the spot price as a fraction of the full instance price.
      def spot_price_fraction(val=nil)
        if val
          spot_price( price.to_f * val )
        else
          spot_price / price rescue 0
        end
      end

      # Rackspace User data -- DNA typically used to bootstrap the machine.
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

      def image_info
        Chef::Config[:rackspace_image_info][ [bits, image_name] ] or ( ui.warn "Make sure to define the machine's bits and image_name. (Have #{[bits, image_name].inspect})" ; {} )
      end

      def list_images
        ui.info("Available images:")
        Chef::Config[:rackspace_image_info].each do |flavor_name, flavor|
          ui.info("  #{flavor_name}\t#{flavor.inspect}")
        end
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


      FLAVOR_INFO = {
        '1'               => { :price => 0.00,  :bits => '64-bit', :ram =>    256, :cores => 1, :core_size => 0.25, :inst_disks => 0, :inst_disk_size =>    0, :ephemeral_volumes => 0 },
      }

      #
      # To add to this list, use this snippet:
      #
      #     Chef::Config[:rackspace_image_info] ||= {}
      #     Chef::Config[:rackspace_image_info].merge!({
      #       # ... lines like the below
      #     })
      #
      # in your knife.rb or whereever. We'll notice that it exists and add to it, rather than clobbering it.
      #
      Chef::Config[:rackspace_image_info] ||= {}
      Chef::Config[:rackspace_image_info].merge!({
          %w[ 64-bit natty ]    => { :image_id => '115', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
          %w[ 64-bit oneiric ]  => { :image_id => '119', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        })
    end

    class Terremark < Base
      # password, username, service
    end
  end
end
