#
# Hadoop aspects for poolparty and chef
#

# Poolparty rules to make the node act as part of a cluster.
# Assigns security group named after the cluster (eg 'clyde') and after the
# cluster-role (eg 'clyde-master')
def is_hadoop_node settings
  has_role settings, "hadoop"
  security_group POOL_NAME do
    authorize :group_name => POOL_NAME
  end
  security_group do
    authorize :from_port => 22,  :to_port => 22
    authorize :from_port => 80,  :to_port => 80
  end
end
