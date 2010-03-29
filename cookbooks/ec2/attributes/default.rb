# if attribute?(:ec2) && ec2[:userdata]
#   ec2_userdata JSON.parse(ec2[:userdata])
#   ec2_userdata.each do |k,v|
#     send(k.to_s, v)
#   end
# end
