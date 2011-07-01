packages_list = %w[
  ifstat
  iotop
  gt5
  elinks
]
if node[:lsb][:release].to_f > 9.0
  packages_list += %w[ jardiff ]
end
if node[:lsb][:release].to_f > 10.0
  packages_list += %w[  ]
end

if node[:lsb][:release].to_f < 10.10
  packages_list += %w[ rdoc libopenssl-ruby ]
else
  packages_list += %w[ libruby-extras ]
end

packages_list.each do |pkg|
  package pkg
end
