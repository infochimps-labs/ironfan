#
# Chef client/server aspects for poolparty and chef
#

# Poolparty rules to make the node act as a chef server
def is_chef_server settings
  has_role settings, "chef_server"
  security_group 'chef-server' do
    authorize :from_port => 22,   :to_port => 22
    authorize :from_port => 80,   :to_port => 80
    authorize :from_port => 4000, :to_port => 4000  # chef-server-api
    authorize :from_port => 4040, :to_port => 4040  # chef-server-webui
  end
end

# Poolparty rules to make the node act as a chef client
def is_chef_client settings
  get_chef_validation_key settings
  security_group 'chef-client' do
    authorize :from_port => 22, :to_port => 22
  end
  has_role settings, "chef_client"
end
