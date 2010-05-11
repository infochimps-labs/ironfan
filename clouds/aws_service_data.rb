module AwsServiceData
  INSTANCE_PRICES = {
    'm1.small'    => 0.085, 'c1.medium'   => 0.17,  'm1.large'    => 0.34,  'c1.xlarge'   => 0.68,
    'm1.xlarge'   => 0.68,  'm2.xlarge'   => 0.50,  'm2.xlarge'   => 1.20,  'm2.4xlarge'  => 2.40,
  }

  # http://uec-images.ubuntu.com/releases/lucid/rc/
  # http://uec-images.ubuntu.com/releases/karmic/

  AMI_MAPPING =  {
    %w[us-east-1             64-bit  instance        karmic    ] => 'ami-55739e3c',
    %w[us-east-1             32-bit  instance        karmic    ] => 'ami-bb709dd2',
    %w[us-west-1             64-bit  instance        karmic    ] => 'ami-cb2e7f8e',
    %w[us-west-1             32-bit  instance        karmic    ] => 'ami-c32e7f86',
    %w[eu-west-1             64-bit  instance        karmic    ] => 'ami-05c2e971',
    %w[eu-west-1             32-bit  instance        karmic    ] => 'ami-2fc2e95b',
    #
    %w[ap-southeast-1        32-bit  ebs             lucid     ] => 'ami-27f18e75',
    %w[ap-southeast-1        32-bit  instance        lucid     ] => 'ami-3ff18e6d',
    %w[ap-southeast-1        64-bit  ebs             lucid     ] => 'ami-2bf18e79',
    %w[ap-southeast-1        64-bit  instance        lucid     ] => 'ami-21f18e73',
    %w[eu-west-1             32-bit  ebs             lucid     ] => 'ami-af476ddb',
    %w[eu-west-1             32-bit  instance        lucid     ] => 'ami-b9476dcd',
    %w[eu-west-1             64-bit  ebs             lucid     ] => 'ami-a9476ddd',
    %w[eu-west-1             64-bit  instance        lucid     ] => 'ami-ad476dd9',
    %w[us-east-1             32-bit  ebs             lucid     ] => 'ami-2fa14846',
    %w[us-east-1             32-bit  instance        lucid     ] => 'ami-e3ae478a',
    %w[us-east-1             64-bit  ebs             lucid     ] => 'ami-23a1484a',
    %w[us-east-1             64-bit  instance        lucid     ] => 'ami-8bae47e2',
    %w[us-west-1             32-bit  ebs             lucid     ] => 'ami-e998c9ac',
    %w[us-west-1             32-bit  instance        lucid     ] => 'ami-df98c99a',
    %w[us-west-1             64-bit  ebs             lucid     ] => 'ami-eb98c9ae',
    %w[us-west-1             64-bit  instance        lucid     ] => 'ami-db98c99e',
    #
    %w[us-west-1             32-bit  ebs             chef-server ] => 'ami-b99ecffc',  # ami-7b9fce3e
    %w[us-west-1             32-bit  instance        chef-client ] => 'ami-b39ccdf6',
    %w[us-east-1             32-bit  instance        chef-client ] => 'ami-17b35a7e',
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
    AMI_MAPPING[ [settings[:aws_region], bits, settings[:instance_backing], settings[:instance_os]] ]
  end

  def self.info_for_ami ami_id
    AmiInfo.new *AMI_MAPPING.invert[ami_id]
  end

  # EC2_URLS = {
  #   'us-west-1' => 'https://us-west-1.ec2.amazonaws.com',
  # }
end
