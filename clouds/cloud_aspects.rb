# Load settings from ~/.hadoop-ec2/poolparty.yaml
# Node/cluster/common settings are merged in #settings_for_node (below)
require 'configliere'
require File.join(File.dirname(__FILE__), 'aws_service_data')
Settings.define :access_key,        :env_var => 'AWS_ACCESS_KEY_ID',         :description => 'Your aws access key ID -- visit "Security Credentials" from the AWS "Account" page.'
Settings.define :secret_access_key, :env_var => 'AWS_SECRET_ACCESS_KEY',     :description => 'Your aws secret access key -- visit "Security Credentials" from the AWS "Account" page.'
Settings.define :account_id,        :env_var => 'AWS_ACCOUNT_ID',            :description => 'Your AWS account ID -- look in the top right corner of the credentials page from "Your Account" on the AWS homepage. Omit all dashes: eg 123456789012'
Settings.define :ec2_url,           :env_var => 'EC2_URL',                   :description => 'EC2 endpoint URL for api calls; should match the AWS region; eg https://us-west-1.ec2.amazonaws.com for us-west-1'
Settings.define :aws_region,                                                 :description => 'AWS region: currently, us-east-1, us-west-1, eu-west-1, or ap-southeast-1'
Settings.read File.join(File.dirname(__FILE__), '/../config/cluster_chef_defaults.yaml')
Settings.read File.join(ENV['HOME'],'.hadoop-ec2','poolparty.yaml');
Settings.resolve!

# ===========================================================================
#
# Generic aspects
#

# Poolparty definitions for a generic node.
def is_generic_node settings
  # Instance described in settings files
  instance_type           settings[:instance_type]
  image_id                AwsServiceData.ami_for(settings)
  availability_zones      settings[:availability_zones]
  disable_api_termination settings[:disable_api_termination]  if settings[:instance_backing] == 'ebs'
  elastic_ip              settings[:elastic_ip]               if settings[:elastic_ip]
  set_instance_backing    settings
  keypair                 POOL_NAME, File.join(ENV['HOME'], '.poolparty', 'keypairs')
  has_role settings, "base_role"
  # has_role settings, "infochimps_base"
  settings[:attributes][:cluster_name] = self.parent.name
  settings[:attributes][:cluster_role] = self.name
end

# Poolparty rules to impart the 'big_package' role:
# installs a whole mess of convenient packages.
def has_big_package settings
  has_role settings, "big_package"
  has_role settings, "dev_machine"
end

# ===========================================================================
#
# AWS aspects
#

def sends_aws_keys settings
  settings[:attributes][:aws] ||= {}
  settings[:attributes][:aws][:access_key]        ||= Settings[:access_key]
  settings[:attributes][:aws][:secret_access_key] ||= Settings[:secret_access_key]
  settings[:attributes][:aws][:aws_region]        ||= Settings[:aws_region]
end

def set_instance_backing settings
  if settings[:instance_backing] == 'ebs'
    # Bring the ephemeral storage (local scratch disks) online
    block_device_mapping([
        { :device_name => '/dev/sda1' }.merge(settings[:boot_volume]||{}),
        { :device_name => '/dev/sdc',  :virtual_name => 'ephemeral0' },
      ])
    instance_initiated_shutdown_behavior 'stop'
  else
    settings.delete :boot_volume
  end
end

# Poolparty rules to impart the 'ebs_volumes_attach' role
def attaches_ebs_volumes settings
  has_role settings, "ebs_volumes_attach"
end

# Poolparty rules to impart the 'ebs_volumes_mount' role
def mounts_ebs_volumes settings
  has_role settings, "ebs_volumes_mount"
end

def is_spot_priced settings
  if    settings[:spot_price_fraction].to_f > 0
    spot_price( AwsServiceData::INSTANCE_PRICES[settings[:instance_type]] * settings[:spot_price_fraction] )
  elsif settings[:spot_price].to_f > 0
    spot_price( settings[:spot_price].to_f )
  end
end

# ===========================================================================
#
# Chef aspects
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
  end
  has_role settings, "chef_client"
end

def bootstrap_chef_script role, settings
  erubis_template(
    File.dirname(__FILE__)+"/../config/user_data_script-#{role}.sh.erb",
    :public_ip        => settings[:elastic_ip],
    :hostname         => settings[:attributes][:node_name],
    :chef_server_fqdn => settings[:attributes][:chef][:chef_server].gsub(%r{http://(.*):\d+},'\1'),
    :ubuntu_version   => 'lucid',
    :bootstrap_scripts_url_base => settings[:bootstrap_scripts_url_base],
    :chef_config      => settings[:attributes]
    )
end

def send_runlist_to_chef_server
  raise "not yet"
end

# ===========================================================================
#
# NFS aspects
#

# Poolparty rules to make the node act as an NFS server.  The way this is set
# up, NFS server has open ports to each NFS client, but NFS clients don't
# necessarily have open access to each other.
def is_nfs_server settings
  has_role settings, "nfs_server"
  security_group 'nfs-client'
  security_group 'nfs-server' do
    authorize :group_name => 'nfs-client'
  end
end

# Poolparty rules to make the node act as an NFS server.
# Assigns the security group (thus gaining port access to the server)
# and stuffs in some chef attributes to mount the home drive
def is_nfs_client settings
  has_role settings, "nfs_client"
  security_group 'nfs-client'
end

# ===========================================================================
#
# Hadoop aspects
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

def is_hadoop_master settings
  has_role settings, "hadoop_master"
end

# Poolparty rules to make the node act as a worker in a hadoop cluster It looks
# up the master node's private IP address and passes that to the chef
# attributes.
def is_hadoop_worker settings
  has_role settings, "hadoop_worker"
  master_private_ip   = pool.clouds['master'].nodes.first.private_ip rescue nil
  if master_private_ip
    settings[:attributes].deep_merge!(
      :hadoop => {
        :jobtracker_address => master_private_ip,
        :namenode_address   => master_private_ip, } )
  end
end

# ===========================================================================
#
# Cassandra aspects
#

def is_cassandra_node settings
  has_role settings, "cassandra_node"
  security_group 'cassandra_node' do
    authorize :group_name => 'cassandra_node'
  end
end

# ===========================================================================
#
# Support functions
#

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
  configure_aws_region node_settings
  node_settings
end


# Use the availability_zone to set the region and ec2_url settings.
def configure_aws_region settings
  settings[:aws_region] ||= settings[:availability_zones].first.gsub(/^(\w+-\w+-\d)[a-z]/, '\1')
  settings[:ec2_url]    ||= "https://#{settings[:aws_region]}.ec2.amazonaws.com"

  unless ((ENV['EC2_URL'].to_s == '' && settings[:aws_region] == 'us-east-1') || (ENV['EC2_URL'] == settings[:ec2_url]))
    warn "******\nThe EC2_URL environment variable should probably be #{settings[:ec2_url]} (from your availability zone), not #{AWS::EC2::DEFAULT_HOST}. Try invoking 'export EC2_URL=#{settings[:ec2_url]}' and re-run.\n******"
  end
end

# add a role to the node's run_list.
def has_role settings, role
  settings[:attributes][:run_list] << "role[#{role}]"
end

def has_recipe settings, recipe
  settings[:attributes][:run_list] << recipe
end

# Takes the template file and has Erubis cram the given variables in it
def erubis_template template_filename, *args
  require 'erubis'
  template   = Erubis::Eruby.new File.read(template_filename)
  text       = template.result *args
  text
end
