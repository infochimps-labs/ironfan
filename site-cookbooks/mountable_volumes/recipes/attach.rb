include_recipe "aws"

vols = attachable_volumes(:ebs)
aws  = mntvol_aws_credentials
if vols && aws
  vols.each do |name, conf|
    
    aws_ebs_volume "attach ebs volume #{conf.inspect}" do
      provider              "aws_ebs_volume"
      aws_access_key        aws[:aws_access_key_id]
      aws_secret_access_key aws[:aws_secret_access_key]
      aws_region            aws[:aws_region]
      availability_zone     aws[:availability_zone]
      volume_id             conf[:volume_id]
      device                conf[:device]
      action                :attach
    end
    
  end
end
