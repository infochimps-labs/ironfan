#
# Cassandra aspects for poolparty and chef
#

def is_cassandra_node settings
  has_role settings, "cassandra_node"
  security_group 'cassandra_node' do
    authorize :group_name => 'cassandra_node'
  end
end
