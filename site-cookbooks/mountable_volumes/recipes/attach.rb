include_recipe "aws"

aws  = mntvol_aws_credentials

if aws
  attachable_volumes(:ebs).each do |vol_name, vol|
    
    aws_ebs_volume "attach ebs volume #{vol.inspect}" do
      provider              "aws_ebs_volume"
      aws_access_key        aws[:aws_access_key_id]
      aws_secret_access_key aws[:aws_secret_access_key]
      aws_region            aws[:aws_region]
      availability_zone     aws[:availability_zone]
      volume_id             vol['volume_id']
      device                vol['device']
      action                :attach
    end
    
  end
end
