#
# Hadoop aspects for poolparty and chef
#

# Poolparty rules to make the node act as part of a cluster.
def is_hadoop_node settings
  has_role settings, "hadoop"
end
