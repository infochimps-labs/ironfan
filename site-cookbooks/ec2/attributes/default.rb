#
#
# XXX: this only supports 0 at the current time
default[:ec2][:raid][:level] = 0

default[:ec2][:raid][:read_ahead] = 65536

default[:ec2][:raid][:mount] = "/raid0"
