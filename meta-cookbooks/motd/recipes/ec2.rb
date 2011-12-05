

[ :instance_id, :instance_type, :public_hostname, ].each{|v| node[:motd][v] = (node[:ec2]   || {})[v] || '' }
[ :security_groups,                               ].each{|v| node[:motd][v] = (node[:ec2]   || {})[v] || [] }
[ :description                                    ].each{|v| node[:motd][v] = (node[:lsb]   || {})[v] || '' }
