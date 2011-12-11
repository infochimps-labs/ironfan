
default[:volumes] ||= Mash.new

# where should we get the AWS keys?
default[:metachef][:aws_credential_source] = :data_bag
# the key within that data bag
default[:metachef][:aws_credential_handle] = 'main'
