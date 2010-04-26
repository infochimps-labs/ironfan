require 'configliere'
Settings.read File.join(ENV['HOME'],'.hadoop-ec2','poolparty.yaml'); Settings.resolve!

#
# Build settings for a given cluster_name and role folding together the common
# settings for everything, common settings for cluster, and the role itself.
#
def settings_for_node cluster_name, cluster_role
  cluster_name = cluster_name.to_sym
  cluster_role = cluster_role.to_sym
  node_settings = { :attributes => { :run_list => [] } }.deep_merge(Settings)
  node_settings.delete :pools
  node_settings = node_settings.deep_merge(
    Settings[:pools][cluster_name][:common]      ||{ }).deep_merge(
    Settings[:pools][cluster_name][cluster_role] ||{ })
end

# Poolparty definitions for a generic node.
def is_generic_node settings
  # Instance described in settings files
  instance_type           settings[:instance_type]
  image_id                settings[:ami_id]
  availability_zones      settings[:availability_zones]
  disable_api_termination settings[:disable_api_termination]
  elastic_ip              settings[:elastic_ip] if settings[:elastic_ip]
  keypair                 POOL_NAME, File.join(ENV['HOME'], '.poolparty', 'keypairs')
  settings[:attributes][:run_list]     << 'role[base_role]'
  settings[:attributes][:run_list]     << 'role[infochimps_base]'
  settings[:attributes][:cluster_name] = self.parent.name
  settings[:attributes][:cluster_role] = self.name
end

def is_ebs_backed settings
  # Bring the ephemeral storage (local scratch disks) online
  block_device_mapping([
      { :device_name => '/dev/sda1' }.merge(settings[:boot_volume]||{}),
      { :device_name => '/dev/sdc',  :virtual_name => 'ephemeral0' },
    ])
  instance_initiated_shutdown_behavior 'stop'
end

# Poolparty rules to impart the 'big_package' role:
# installs a whole mess of convenient packages.
def has_big_package settings
  settings[:attributes][:run_list] << 'role[big_package]'
  settings[:attributes][:run_list] << 'role[dev_machine]'
end

# Poolparty rules to impart the 'ebs_volumes_attach' role
def attaches_ebs_volumes settings
  settings[:attributes][:run_list] << 'role[ebs_volumes_attach]'
end

# Poolparty rules to impart the 'ebs_volumes_mount' role
def mounts_ebs_volumes settings
  settings[:attributes][:run_list] << 'role[ebs_volumes_mount]'
end

# Poolparty rules to make the node act as a chef server
def is_chef_server settings
  security_group 'chef-server' do
    authorize :from_port => 22,   :to_port => 22
    authorize :from_port => 80,   :to_port => 80
    authorize :from_port => 4000, :to_port => 4000  # chef-server-api
    authorize :from_port => 4040, :to_port => 4040  # chef-server-webui
  end
  settings[:attributes][:run_list] << 'role[chef_server]'
end

def get_chef_validation_key settings
  chef_settings  = settings[:attributes][:chef] or return
  validation_key_file = File.expand_path(chef_settings[:validation_key_file])
  return unless File.exists?(validation_key_file)
  chef_settings[:validation_key] ||= File.read(validation_key_file)
end

# Poolparty rules to make the node act as a chef client
def is_chef_client settings
  get_chef_validation_key settings
  security_group 'chef-client' do
    authorize :from_port => 22, :to_port => 22
    authorize :group_name => 'chef-server'
  end
  settings[:attributes][:run_list] << 'role[chef_client]'
end

# Poolparty rules to make the node act as an NFS server.  The way this is set
# up, NFS server has open ports to each NFS client, but NFS clients don't
# necessarily have open access to each other.
def is_nfs_server settings
  security_group 'nfs-server' do
    authorize :group_name => 'nfs-client'
  end
  settings[:attributes][:run_list] << 'role[nfs_server]'
end

# Poolparty rules to make the node act as an NFS server.
# Assigns the security group (thus gaining port access to the server)
# and stuffs in some chef attributes to mount the home drive
def is_nfs_client settings
  security_group 'nfs-client'
  settings[:attributes][:run_list] << 'role[nfs_client]'
end

# Poolparty rules to make the node act as part of a cluster.
# Assigns security group named after the cluster (eg 'clyde') and after the
# cluster-role (eg 'clyde-master')
def is_hadoop_node settings
  security_group POOL_NAME do
    authorize :group_name => POOL_NAME
  end
  security_group do
    authorize :from_port => 22,  :to_port => 22
    authorize :from_port => 80,  :to_port => 80
  end
  settings[:attributes][:run_list] << 'role[hadoop]'
end

def is_hadoop_master settings
  settings[:attributes][:run_list] << 'role[hadoop_master]'
end

# Poolparty rules to make the node act as a worker in a hadoop cluster It looks
# up the master node's private IP address and passes that to the chef
# attributes.
def is_hadoop_worker settings
  master_private_ip   = pool.clouds['master'].nodes.first.private_ip rescue nil
  if master_private_ip
    settings[:attributes].deep_merge!(
      :hadoop => {
        :jobtracker_hostname => master_private_ip,
        :namenode_hostname   => master_private_ip, } )
  end
  settings[:attributes][:run_list] << 'role[hadoop_worker]'
end

def is_cassandra_node settings
  settings[:attributes][:run_list] << 'role[cassandra_node]'
  security_group 'cassandra_node' do
    authorize :group_name => 'cassandra_node'
  end
end

def erubis_template template_filename, *args
  require 'erubis'
  template   = Erubis::Eruby.new File.read(template_filename)
  text       = template.result *args
  text
end

def bootstrap_chef_server_script settings
  erubis_template(
    'config/user_data_script-bootstrap_chef_server.sh.erb',
    :public_ip => settings[:elastic_ip],
    :hostname  => settings[:attributes][:node_name],
    :bootstrap_scripts_url_base => settings[:bootstrap_scripts_url_base]
    )
end

INSTANCE_PRICES = {
  'm1.small'    => 0.085, 'c1.medium'   => 0.17,  'm1.large'    => 0.34,  'c1.xlarge'   => 0.68,
  'm1.xlarge'   => 0.68,  'm2.xlarge'   => 0.50,  'm2.xlarge'   => 1.20,  'm2.4xlarge'  => 2.40,
}
def is_spot_priced settings
  if    settings[:spot_price_fraction].to_f > 0
    spot_price( INSTANCE_PRICES[settings[:instance_type]] * settings[:spot_price_fraction])
  elsif settings[:spot_price].to_f > 0
    spot_price( settings[:spot_price].to_f )
  end
end

def send_runlist_to_chef_server
  raise "not yet"
end

