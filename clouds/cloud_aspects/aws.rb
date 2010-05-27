#
# AWS aspects for poolparty and chef
#


# Use the availability_zone to set the region and ec2_url settings.
def configure_aws_region settings
  settings[:aws_region] ||= settings[:availability_zones].first.gsub(/^(\w+-\w+-\d)[a-z]/, '\1')
  settings[:ec2_url]    ||= "https://#{settings[:aws_region]}.ec2.amazonaws.com"
  unless ((ENV['EC2_URL'].to_s == '' && settings[:aws_region] == 'us-east-1') || (ENV['EC2_URL'] == settings[:ec2_url]))
    warn "******\nThe EC2_URL environment variable should probably be #{settings[:ec2_url]} (from your availability zone), not #{AWS::EC2::DEFAULT_HOST}. Try invoking 'export EC2_URL=#{settings[:ec2_url]}' and re-run.\n******"
  end
end

# Add the AWS keys to the attributes hash.  This makes the AWS keys available to
# all chef recipes
def sends_aws_keys settings
  settings[:user_data][:attributes][:aws] ||= {}
  settings[:user_data][:attributes][:aws][:access_key]        ||= Settings[:access_key]
  settings[:user_data][:attributes][:aws][:secret_access_key] ||= Settings[:secret_access_key]
  settings[:user_data][:attributes][:aws][:aws_region]        ||= Settings[:aws_region]
end

def set_instance_backing settings
  if settings[:instance_backing] == 'ebs'
    # Bring the ephemeral storage (local scratch disks) online
    block_device_mapping([
        { :device_name => '/dev/sda1' }.merge(settings[:boot_volume]||{}),
        { :device_name => '/dev/sdc',  :virtual_name => 'ephemeral0' },
      ])
    instance_initiated_shutdown_behavior 'stop'
  else
    settings.delete :boot_volume
  end
end

# Poolparty rules to impart the 'ebs_volumes_attach' role
def attaches_ebs_volumes settings
  has_role settings, "ebs_volumes_attach"
end

# Poolparty rules to impart the 'ebs_volumes_mount' role
def mounts_ebs_volumes settings
  has_role settings, "ebs_volumes_mount"
end

def is_spot_priced settings
  if    settings[:spot_price_fraction].to_f > 0
    spot_price( AwsServiceData::INSTANCE_PRICES[settings[:instance_type]] * settings[:spot_price_fraction] )
  elsif settings[:spot_price].to_f > 0
    spot_price( settings[:spot_price].to_f )
  end
end
