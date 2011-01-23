module AwsServiceData
  INSTANCE_PRICES = {
    'm1.small'    => 0.085, 'c1.medium'   => 0.17,  'm1.large'    => 0.34,  'c1.xlarge'   => 0.68,
    'm1.xlarge'   => 0.68,  'm2.xlarge'   => 0.50,  'm2.2xlarge'  => 1.20,  'm2.4xlarge'  => 2.40,
    't1.micro'    => 0.02,
  }

  # http://uec-images.ubuntu.com/releases/lucid/release/
  # http://uec-images.ubuntu.com/releases/karmic/

  AMI_MAPPING =  {
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
  AmiInfo = Struct.new(:region, :bits, :backing, :os)

  # Given an instance type, return its bit-ness
  def self.bits_for_instance instance_type
    case instance_type
    when 'm1.small', 'c1.medium' then '32-bit'
    else                              '64-bit'
    end
  end

  # Lookup the ami for the given hash, specifying
  #
  # * +:instance_type+ = 'm1.small', 'c1.xlarge', etc.
  # * +:aws_region+    = 'us-east-1', etc
  # * +:instance_backing+ should be 'ebs' or 'instance'
  # * +:instance_os+ either 'lucid' (currently, Ubuntu 10.04rc1) or 'karmic' (Ubuntu 9.10)
  #
  # @example
  #   get_ami_for :instance_type => 'm1.small', :aws_region => 'us-east-1', :instance_backing => 'instance', :instance_os => 'karmic'
  #   # => "ami-bb709dd2"
  #
  def self.ami_for settings
    bits = bits_for_instance(settings[:instance_type])
    ami = AMI_MAPPING[ [settings[:aws_region], bits, settings[:instance_backing], settings[:instance_os]] ]
    raise "No AMI found for #{[ settings[:aws_region], bits, settings[:instance_backing], settings[:instance_os] ].inspect}" unless ami
    ami
  end

  def self.info_for_ami ami_id
    AmiInfo.new *AMI_MAPPING.invert[ami_id]
  end

  # EC2_URLS = {
  #   'us-west-1' => 'https://us-west-1.ec2.amazonaws.com',
  # }
end
