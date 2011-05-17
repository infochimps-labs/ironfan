
module ClusterChef
  module Cloud
    class Base < ClusterChef::DslObject
      has_keys :name, :flavor, :image_name, :image_id, :keypair

      def initialize
        super
      end

      # The username to ssh with.
      # @return the ssh_user if set explicitly; otherwise, the user implied by the image name, if any; or else 'root'
      def ssh_user val=nil
        from_setting_or_image_info :ssh_user, val, 'root'
      end

      # The directory holding
      def ssh_identity_dir val=nil
        set :ssh_identity_dir, File.expand_path(val) unless val.nil?
        @settings.include?(:ssh_identity_dir) ? @settings[:ssh_identity_dir] : File.expand_path('~/.chef/keypairs')
      end

      # The SSH identity file used for authentication
      def ssh_identity_file val=nil
        set :ssh_identity_file, File.expand_path(val) unless val.nil?
        @settings.include?(:ssh_identity_file) ? @settings[:ssh_identity_file] : File.join(ssh_identity_dir, "#{keypair}.pem")
      end

      # The ID of the image to use.
      # @return the image_id if set explicitly; otherwise, the id implied by the image name
      def image_id val=nil
        from_setting_or_image_info :image_id, val
      end

      # The distribution knife should target when bootstrapping an instance
      # @return the bootstrap_distro if set explicitly; otherwise, the bootstrap_distro implied by the image name
      def bootstrap_distro val=nil
        from_setting_or_image_info :bootstrap_distro, val, "ubuntu10.04-gems"
      end

      def from_setting_or_image_info key, val=nil, default=nil
        @settings[key] = val unless val.nil?
        return @settings[key]  if @settings.include?(key)
        return image_info[key] if image_info && image_info.includes?(key)
        return default       # otherwise
      end
    end

    class Ec2 < Base
      has_keys(
        :region, :availability_zones, :backing, :permanent, :elastic_ip,
        :spot_price, :spot_price_fraction, :user_data, :security_groups)

      def initialize *args
        super *args
        @settings[:security_groups] = {}
        @settings[:user_data]       = {}
      end

      # An alias for disable_api_termination. Prevents the instance from being
      # terminated without flipping its disable_api_termination attribute back
      # to false
      def permanent val=nil
        set :disable_api_termination, val
      end

      # The instance price, drawn from the compute flavor's info
      def price
        flavor_info[:price]
      end

      # The instance bitness, drawn from the compute flavor's info
      def bits
        flavor_info[:bits]
      end

      # adds a security group to the cloud instance
      def security_group sg_name, &block
        security_groups[sg_name] ||= ClusterChef::Cloud::SecurityGroup.new(self, sg_name)
        security_groups[sg_name].instance_eval(&block) if block
        security_groups[sg_name]
      end

      # With a value, sets the spot price to the given fraction of the
      #   instance's full price (as found in ClusterChef::Cloud::Aws::FLAVOR_INFO)
      # With no value, returns the spot price as a fraction of the full instance price.
      def spot_price_fraction val=nil
        if val
          spot_price( price.to_f * val )
        else
          spot_price / price rescue 0
        end
      end

      def validation_key
        IO.read(Chef::Config[:validation_key]) rescue ''
      end

      # When given a hash, merge with the existing user data
      #
      # FIXME: use a deep merge
      def user_data hsh={}
        @settings[:user_data] ||= {}
        if hsh.empty?
          @settings[:user_data].merge({
              :chef_server            => Chef::Config.chef_server_url,
              :validation_client_name => Chef::Config.validation_client_name,
              :validation_key         => validation_key,
            })
        else
          @settings[:user_data].merge! hsh
          user_data
        end
      end

      def merge! cloud
        @settings = cloud.to_hash.merge @settings
        @settings[:security_groups] = cloud.security_groups.merge(self.security_groups)
        @settings[:user_data]       = cloud.to_hash[:user_data].merge(@settings[:user_data])
      end

      def resolve! cloud
        merge! cloud
        resolve_region!
        resolve_block_device_mapping!
        self
      end

      def resolve_region!
        return unless availabiltiy_zones
        region availability_zones.first.gsub(/^(\w+-\w+-\d)[a-z]/, '\1') if !region || (region.empty? && availability_zones && !availability_zones.empty?)
      end

      def resolve_block_device_mapping!
        # FIXME: finish this
        # if settings[:instance_backing] == 'ebs'
        #   # Bring the ephemeral storage (local scratch disks) online
        #   block_device_mapping([
        #       { :device_name => '/dev/sda1' }.merge(settings[:boot_volume]||{}),
        #       { :device_name => '/dev/sdc',  :virtual_name => 'ephemeral0' },
        #     ])
        #   instance_initiated_shutdown_behavior 'stop'
        # else
        #   settings.delete :boot_volume
        # end
      end

      # Utility methods

      # def to_hash
      #   [ :provider, :keypair,
      #     :region, :availability_zones,
      #     :flavor, :instance_backing,
      #     :image_name, :image_id, :bits,
      #     :ssh_user, :bootstrap_distro, :ssh_identity_file,
      #     :permanent, :elastic_ip,
      #     :price, :spot_price, :spot_price_fraction,
      #     :flavor_info,
      #     :user_data,
      #     :security_groups,
      #   ].inject({}){|h,k| h[k] = send(k) ; h }
      # end

      def image_info
        IMAGE_INFO[ [region, bits, backing, image_name] ] or warn "Make sure to define the machine's region, bits, backing and image_name. (Have #{[region, bits, backing, image_name].inspect})"
      end

      def flavor_info
        FLAVOR_INFO[ flavor ] || {} # or raise "Please define the machine's flavor."
      end

      FLAVOR_INFO = {
        'm1.small'    => { :price => 0.085, :bits => '32-bit', :ram => 0, :cores => 0, :core_size => 0, },
        'c1.medium'   => { :price => 0.17,  :bits => '32-bit', :ram => 0, :cores => 0, :core_size => 0, },
        'm1.large'    => { :price => 0.34,  :bits => '64-bit', :ram => 0, :cores => 0, :core_size => 0, },
        'c1.xlarge'   => { :price => 0.68,  :bits => '64-bit', :ram => 0, :cores => 0, :core_size => 0, },
        'm1.xlarge'   => { :price => 0.68,  :bits => '64-bit', :ram => 0, :cores => 0, :core_size => 0, },
        'm2.xlarge'   => { :price => 0.50,  :bits => '64-bit', :ram => 0, :cores => 0, :core_size => 0, },
        'm2.2xlarge'  => { :price => 1.20,  :bits => '64-bit', :ram => 0, :cores => 0, :core_size => 0, },
        'm2.4xlarge'  => { :price => 2.40,  :bits => '64-bit', :ram => 0, :cores => 0, :core_size => 0, },
        't1.micro'    => { :price => 0.02,  :bits => '64-bit', :ram => 0, :cores => 0, :core_size => 0, },
      }

      IMAGE_INFO =  {
        %w[us-east-1             64-bit  instance        karmic                     ] => { :image_id => 'ami-55739e3c', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[us-east-1             32-bit  instance        karmic                     ] => { :image_id => 'ami-bb709dd2', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[us-west-1             64-bit  instance        karmic                     ] => { :image_id => 'ami-cb2e7f8e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[us-west-1             32-bit  instance        karmic                     ] => { :image_id => 'ami-c32e7f86', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[eu-west-1             64-bit  instance        karmic                     ] => { :image_id => 'ami-05c2e971', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[eu-west-1             32-bit  instance        karmic                     ] => { :image_id => 'ami-2fc2e95b', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

        #
        # Lucid (Ubuntu 10.10)
        #
        %w[ap-southeast-1        64-bit  ebs             lucid                      ] => { :image_id => 'ami-77f28d25', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ap-southeast-1        32-bit  ebs             lucid                      ] => { :image_id => 'ami-4df28d1f', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ap-southeast-1        64-bit  instance        lucid                      ] => { :image_id => 'ami-57f28d05', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ap-southeast-1        32-bit  instance        lucid                      ] => { :image_id => 'ami-a5f38cf7', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[eu-west-1             64-bit  ebs             lucid                      ] => { :image_id => 'ami-ab4d67df', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[eu-west-1             32-bit  ebs             lucid                      ] => { :image_id => 'ami-a94d67dd', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[eu-west-1             64-bit  instance        lucid                      ] => { :image_id => 'ami-a54d67d1', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[eu-west-1             32-bit  instance        lucid                      ] => { :image_id => 'ami-cf4d67bb', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        #
        %w[us-east-1             64-bit  ebs             lucid                      ] => { :image_id => 'ami-4b4ba522', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[us-east-1             32-bit  ebs             lucid                      ] => { :image_id => 'ami-714ba518', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[us-east-1             64-bit  instance        lucid                      ] => { :image_id => 'ami-fd4aa494', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[us-east-1             32-bit  instance        lucid                      ] => { :image_id => 'ami-2d4aa444', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        #
        %w[us-west-1             64-bit  ebs             lucid                      ] => { :image_id => 'ami-d197c694', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[us-west-1             32-bit  ebs             lucid                      ] => { :image_id => 'ami-cb97c68e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[us-west-1             64-bit  instance        lucid                      ] => { :image_id => 'ami-c997c68c', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[us-west-1             32-bit  instance        lucid                      ] => { :image_id => 'ami-c597c680', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

        #
        # Maverick (Ubuntu 10.10)
        #
        %w[ ap-southeast-1       64-bit  ebs             maverick                   ] => { :image_id => 'ami-32423c60', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ ap-southeast-1       64-bit  instance        maverick                   ] => { :image_id => 'ami-12423c40', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ ap-southeast-1       32-bit  ebs             maverick                   ] => { :image_id => 'ami-0c423c5e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ ap-southeast-1       32-bit  instance        maverick                   ] => { :image_id => 'ami-7c423c2e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        #
        %w[ eu-west-1            64-bit  ebs             maverick                   ] => { :image_id => 'ami-e59ca991', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ eu-west-1            64-bit  instance        maverick                   ] => { :image_id => 'ami-1b9ca96f', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ eu-west-1            32-bit  ebs             maverick                   ] => { :image_id => 'ami-fb9ca98f', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ eu-west-1            32-bit  instance        maverick                   ] => { :image_id => 'ami-339ca947', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        #
        %w[ us-east-1            64-bit  ebs             maverick                   ] => { :image_id => 'ami-cef405a7', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ us-east-1            64-bit  instance        maverick                   ] => { :image_id => 'ami-08f40561', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ us-east-1            32-bit  ebs             maverick                   ] => { :image_id => 'ami-ccf405a5', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ us-east-1            32-bit  instance        maverick                   ] => { :image_id => 'ami-a6f504cf', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        #
        %w[ us-west-1            64-bit  ebs             maverick                   ] => { :image_id => 'ami-af7e2eea', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ us-west-1            64-bit  instance        maverick                   ] => { :image_id => 'ami-a17e2ee4', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ us-west-1            32-bit  ebs             maverick                   ] => { :image_id => 'ami-ad7e2ee8', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[ us-west-1            32-bit  instance        maverick                   ] => { :image_id => 'ami-957e2ed0', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

        #
        # Infochimps
        #
        # sorry to stuff these in here -- the above are generic, these are infochimps internal
        %w[us-east-1             32-bit  ebs             infochimps-scraper-client  ] => { :image_id => '', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.lucid.east.32bit.20100610a
        %w[us-east-1             64-bit  ebs             infochimps-scraper-client  ] => { :image_id => 'ami-d13ed5b8', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.lucid.east.32bit.20100610a
        %w[us-east-1             64-bit  ebs             infochimps-hadoop-client   ] => { :image_id => 'ami-a236c7cb', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # microchimps
        %w[us-east-1             64-bit  instance        infochimps-hadoop-client-1 ] => { :image_id => 'ami-ad3ad1c4', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.lucid.east.ami-64bit-20100714
        %w[us-east-1             64-bit  instance        infochimps-hadoop-client   ] => { :image_id => 'ami-589c6d31', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.hadoop-client.lucid.east.ami-64bit-20101224b
        #
        %w[us-east-1             32-bit  ebs             infochimps-maverick-client ] => { :image_id => 'ami-32a0535b', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.maverick.east.ami-32bit-20110211
        %w[us-east-1             64-bit  ebs             infochimps-maverick-client ] => { :image_id => 'ami-48be4e21', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.maverick.east.ami-64bit-20110118
        %w[us-east-1             64-bit  instance        infochimps-maverick-client ] => { :image_id => 'ami-50659439', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.hadoop-client.maverick.east.ami-64bit-20110113

        %w[us-east-1             32-bit  ebs             mrflip-maverick-client     ] => { :image_id => 'ami-f4f6069d', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.10-cluster_chef", }, # mrflip.chef-client.maverick.east.ebs-32bit-20110124
      }

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
  end
end
