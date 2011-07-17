packages_list = %w[
  ifstat
  iotop
  gt5
]

if node[:lsb][:release].to_f > 9.0
  packages_list += %w[ ec2-api-tools ec2-ami-tools ]
end

if node[:lsb][:release].to_f > 9.0
  packages_list += %w[ jardiff ]
end
if node[:lsb][:release].to_f > 10.0
  packages_list += %w[  ]
end

packages_list.each do |pkg|
  package pkg
end
