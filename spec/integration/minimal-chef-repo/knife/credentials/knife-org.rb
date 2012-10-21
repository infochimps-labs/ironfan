#
# Put your own AWS credentials in knife-user-ironfantester.rb, not here.
#
Chef::Config.instance_eval do
  organization            "ironfantest"
  chef_server_url         "https://api.opscode.com/organizations/#{organization}"
  validation_client_name  "#{organization}-validator"
  validation_key          "#{credentials_path}/#{organization}-validator.pem"

  Chef::Config[:ec2_image_info] ||= {}
  ec2_image_info.merge!({
      %w[us-east-1  64-bit  ebs  alestic-precise] => { :image_id => 'ami-b0d309d9', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu12.04-gems", },
    })
  Chef::Log.debug("Loaded #{__FILE__}, now have #{ec2_image_info.size} ec2 images")

  # Don't complain about ssh known_hosts
  knife[:host_key_verify]       = false # yeah... so 0.10.7+ uses one, 0.10.4 the other.
  knife[:no_host_key_verify]    = true
end
