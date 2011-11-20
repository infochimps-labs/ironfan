default[:mountable_volumes][:volumes] = {}

# where should we get the AWS keys?
default[:mountable_volumes][:aws_credential_source] = :data_bag
# the key within that data bag
default[:mountable_volumes][:aws_credential_handle] = 'main'
