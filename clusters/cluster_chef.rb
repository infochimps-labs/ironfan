require 'configliere'

class RHash < Hash
  def self.new *args
    super(*args){|h,k| h[k] = RHash.new }
  end
end

def cluster name, &block
  Settings[:cluster_name]       = name
  Settings[name]                = RHash.new
  set[:run_list]                = []
  set[:cloud] = ClusterChef::Cloud::Aws.new
  cloud.keypair name
  # set[:cloud][:security_groups] = [name]
  block.call
  role "#{cluster_name}_cluster"
end

def cloud provider=nil, &block
  set[:cloud].provider provider
  yield set[:cloud] if block
  set[:cloud]
end
def facet facet_name, &block
  role "#{cluster_name}-#{facet_name}"
  block.call
end

# Reads the validation key in directly from a file
def get_chef_validation_key settings
  set[:validation_key_file] = '~/.chef/keypairs/mrflip-validator.pem'
  validation_key_file = File.expand_path(set[:validation_key_file])
  return unless File.exists?(validation_key_file)
  set[:userdata][:validation_key] ||= File.read(validation_key_file)
end

def cluster_name
  Settings[:cluster_name]
end

def set
  Settings[cluster_name]
end

def user_data()               end

def instances n_instances
  set[:instances] = n_instances
end
def role name
  set[:run_list] << "role[#{name}]"
end
def recipe name
  set[:run_list] << name
end

def security_group name, options={}, &block
  set[:cloud][:security_groups] << name
end

def role_implication name
end

def has_dynamic_volumes
  set[:run_list] << 'attaches_volumes'
  set[:run_list] << 'mounts_volumes'
end

def override_attributes options
  set[:override_attributes].merge! options
end

module ClusterChef
  module Cloud

    class Base
      def initialize
        @settings = RHash.new
        @settings[:security_groups] = []
      end

      def set key=nil, val=nil
        @settings[key] = val unless val.nil?
        @settings[key]
      end

      def method_missing meth, *args
        set meth, *args
      end

      def keys
        @settings.keys
      end

      def to_hash
        keys.inject({}){|h,k| h[k] = send(k) ; h }
      end

      def to_s
        to_hash.merge({ :settings => @settings }).to_s
      end

      def from_setting_or_image_info key, val=nil, default=nil
        @settings[key] = val if val
        return @settings[key]  if @settings.include?(key)
        return image_info[key] unless image_info.blank?
        return default             # otherwise
      end
    end

    class Aws < Base
      # The username to ssh with
      def ssh_user val=nil
        from_setting_or_image_info :ssh_user, val, 'root'
      end
      def image_id val=nil
        from_setting_or_image_info :image_id, val
      end
      def bootstrap_distro val=nil
        from_setting_or_image_info :bootstrap_distro, val, "ubuntu10.04-gems"
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

      def spot_price_fraction val=nil
        if val
          spot_price( price.to_f * val )
        else
          spot_price / price rescue 0
        end
      end

      # Utility methods

      def keys
        [ :provider, :keypair,
          :region, :availability_zones,
          :flavor, :instance_backing,
          :image_name, :image_id, :bits, :ssh_user, :bootstrap_distro,
          :permanent, :elastic_ip,
          :price, :spot_price, :spot_price_fraction,
          :flavor_info
        ]
      end

      def image_info
        IMAGE_INFO[ [region, bits, backing, image_name] ] or warn "Make sure to define the machine's region, bits, backing and image_name."
      end

      def flavor_info
        FLAVOR_INFO[ flavor ] or raise "Please define the machine's flavor."
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

      # http://uec-images.ubuntu.com/releases/lucid/release/
      # http://uec-images.ubuntu.com/releases/karmic/

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

        %w[us-east-1             32-bit  instance        opscode-chef-client        ] => { :image_id => 'ami-17f51c7e', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[us-east-1             64-bit  instance        opscode-chef-client        ] => { :image_id => 'ami-eff51c86', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },
        %w[us-east-1             64-bit  ebs             opscode-chef-client        ] => { :image_id => 'ami-a2f405cb', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", },

        #
        # Infochimps
        #
        # # Public AMIs, compatible with chef 0.9+ only
        # %w[us-east-1             32-bit  ebs             infochimps-chef-client   ] => { :image_id => 'ami-393ed550', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.lucid.east.32bit.20100610a
        # %w[us-east-1             64-bit  ebs             infochimps-chef-client   ] => { :image_id => 'ami-813ad1e8', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.lucid.east.64bit.20100612
        # %w[us-east-1             32-bit  instance        infochimps-chef-client   ] => { :image_id => '', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.lucid.east.ami-32bit-20100609
        # %w[us-east-1             64-bit  instance        infochimps-chef-client   ] => { :image_id => '', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.lucid.east.ami-64bit-20100609
        # sorry to stuff these in here -- the above are generic, these are infochimps internal
        %w[us-east-1             32-bit  ebs             infochimps-scraper-client  ] => { :image_id => '', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.lucid.east.32bit.20100610a
        %w[us-east-1             64-bit  ebs             infochimps-scraper-client  ] => { :image_id => 'ami-d13ed5b8', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.lucid.east.32bit.20100610a
        %w[us-east-1             64-bit  ebs             infochimps-hadoop-client   ] => { :image_id => 'ami-a236c7cb', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # microchimps
        %w[us-east-1             64-bit  instance        infochimps-hadoop-client-1 ] => { :image_id => 'ami-ad3ad1c4', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.lucid.east.ami-64bit-20100714
        %w[us-east-1             64-bit  instance        infochimps-hadoop-client   ] => { :image_id => 'ami-589c6d31', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.hadoop-client.lucid.east.ami-64bit-20101224b

        %w[us-east-1             64-bit  ebs             infochimps-chef-client     ] => { :image_id => 'ami-48be4e21', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.chef-client.maverick.east.ami-64bit-20110118

        %w[us-east-1             64-bit  instance        infochimps-maverick-client ] => { :image_id => 'ami-50659439', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-gems", }, # infochimps.hadoop-client.maverick.east.ami-64bit-20110113
      }

    end
  end
end

def compile_cloud
  # set region from AZ's
  # set AMI from region, image_name, backing
  # set ssh_user     from image_name
  # set knife distro from image_name
  # set identity file from keypair
end

# class ClusterChef ; def method_missing(*args) ; end ; end
