module AwsServiceData
  INSTANCE_PRICES = {
    'm1.small'    => 0.085, 'c1.medium'   => 0.17,  'm1.large'    => 0.34,  'c1.xlarge'   => 0.68,
    'm1.xlarge'   => 0.68,  'm2.xlarge'   => 0.50,  'm2.2xlarge'  => 1.20,  'm2.4xlarge'  => 2.40,
  }

  # http://uec-images.ubuntu.com/releases/lucid/release/
  # http://uec-images.ubuntu.com/releases/karmic/

  AMI_MAPPING =  {
    %w[us-east-1             64-bit  instance        karmic      ] => 'ami-55739e3c',
    %w[us-east-1             32-bit  instance        karmic      ] => 'ami-bb709dd2',
    %w[us-west-1             64-bit  instance        karmic      ] => 'ami-cb2e7f8e',
    %w[us-west-1             32-bit  instance        karmic      ] => 'ami-c32e7f86',
    %w[eu-west-1             64-bit  instance        karmic      ] => 'ami-05c2e971',
    %w[eu-west-1             32-bit  instance        karmic      ] => 'ami-2fc2e95b',
    #
    %w[ap-southeast-1        64-bit  ebs             lucid       ] => 'ami-77f28d25',
    %w[ap-southeast-1        32-bit  ebs             lucid       ] => 'ami-4df28d1f',
    %w[ap-southeast-1        64-bit  instance        lucid       ] => 'ami-57f28d05',
    %w[ap-southeast-1        32-bit  instance        lucid       ] => 'ami-a5f38cf7',
    %w[eu-west-1             64-bit  ebs             lucid       ] => 'ami-ab4d67df',
    %w[eu-west-1             32-bit  ebs             lucid       ] => 'ami-a94d67dd',
    %w[eu-west-1             64-bit  instance        lucid       ] => 'ami-a54d67d1',
    %w[eu-west-1             32-bit  instance        lucid       ] => 'ami-cf4d67bb',
    %w[us-east-1             64-bit  ebs             lucid       ] => 'ami-4b4ba522',
    %w[us-east-1             32-bit  ebs             lucid       ] => 'ami-714ba518',
    %w[us-east-1             64-bit  instance        lucid       ] => 'ami-fd4aa494',
    %w[us-east-1             32-bit  instance        lucid       ] => 'ami-2d4aa444',
    %w[us-west-1             64-bit  ebs             lucid       ] => 'ami-d197c694',
    %w[us-west-1             32-bit  ebs             lucid       ] => 'ami-cb97c68e',
    %w[us-west-1             64-bit  instance        lucid       ] => 'ami-c997c68c',
    %w[us-west-1             32-bit  instance        lucid       ] => 'ami-c597c680',
    #
    %w[us-east-1             32-bit  instance        opscode-chef-client ] => 'ami-17f51c7e',
    %w[us-east-1             64-bit  instance        opscode-chef-client ] => 'ami-eff51c86',
    #
    %w[us-east-1             32-bit  ebs             infochimps-chef-client ] => 'ami-449a722d', # infochimps.chef-client.lucid.east.32bit.20100610a
    %w[us-east-1             64-bit  ebs             infochimps-chef-client ] => 'ami-38e40c51', # infochimps.chef-client.lucid.east.64bit.20100612
    %w[us-east-1             32-bit  instance        infochimps-chef-client ] => 'ami-be9c74d7', # infochimps.chef-client.lucid.east.ami-32bit-20100609
    %w[us-east-1             64-bit  instance        infochimps-chef-client ] => 'ami-b29d75db', # infochimps.chef-client.lucid.east.ami-64bit-20100609
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
