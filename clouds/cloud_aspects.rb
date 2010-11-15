# Load settings from ~/.hadoop-ec2/poolparty.yaml
# Node/cluster/common settings are merged in #settings_for_node (below)
require 'configliere'
CLOUD_ASPECTS_DIR=File.dirname(__FILE__)
require CLOUD_ASPECTS_DIR+'/aws_service_data'
require CLOUD_ASPECTS_DIR+'/cloud_aspects/aws'
require CLOUD_ASPECTS_DIR+'/cloud_aspects/chef'
require CLOUD_ASPECTS_DIR+'/cloud_aspects/cassandra'
require CLOUD_ASPECTS_DIR+'/cloud_aspects/hadoop'
require CLOUD_ASPECTS_DIR+'/cloud_aspects/nfs'

Settings.define :access_key,        :env_var => 'AWS_ACCESS_KEY_ID',     :description => 'Your aws access key ID -- visit "Security Credentials" from the AWS "Account" page.'
Settings.define :secret_access_key, :env_var => 'AWS_SECRET_ACCESS_KEY', :description => 'Your aws secret access key -- visit "Security Credentials" from the AWS "Account" page.'
Settings.define :account_id,        :env_var => 'AWS_ACCOUNT_ID',        :description => 'Your AWS account ID -- look in the top right corner of the credentials page from "Your Account" on the AWS homepage. Omit all dashes: eg 123456789012'
Settings.define :ec2_url,           :env_var => 'EC2_URL',               :description => 'EC2 endpoint URL for api calls; should match the AWS region; eg https://us-west-1.ec2.amazonaws.com for us-west-1'
Settings.define :aws_region,                                             :description => 'AWS region: currently, us-east-1, us-west-1, eu-west-1, or ap-southeast-1'
Settings.read File.join(File.dirname(__FILE__), '/../config/cluster_chef_defaults.yaml')
Settings.read File.join(ENV['HOME'],'.hadoop-ec2','poolparty.yaml');
Settings.resolve!

# ===========================================================================
#
# Generic aspects
#

# Poolparty definitions for a generic node.
# Assigns security group named after the cluster (eg 'clyde') and after the
# cluster-role (eg 'clyde-master')
def is_generic_node settings
  # Instance described in settings files
  instance_type           settings[:instance_type]
  image_id                AwsServiceData.ami_for(settings)
  availability_zones      settings[:availability_zones]
  disable_api_termination settings[:disable_api_termination]  if settings[:instance_backing] == 'ebs'
  elastic_ip              settings[:elastic_ip]               if settings[:elastic_ip]
  set_instance_backing    settings
  keypair                 settings[:cluster_name], File.join(ENV['HOME'], '.poolparty', 'keypairs')
  has_role                settings, "base_role"
  settings[:user_data][:attributes][:cluster_name] = settings[:cluster_name]
  settings[:user_data][:attributes][:cluster_role] = settings[:cluster_role]
  security_group settings[:cluster_name] do
    authorize :group_name => settings[:cluster_name]
  end
  security_group do
    authorize :from_port => 22,  :to_port => 22
    authorize :from_port => 80,  :to_port => 80
  end
  security_group "default"
  user                        'ubuntu'
  is_spot_priced              settings
  sends_aws_keys              settings
end

# Poolparty rules to impart the 'big_package' role:
# installs a whole mess of convenient packages.
def has_big_package settings
  has_role settings, "big_package"
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
  node_settings = {
    :user_data => { :attributes => { :run_list => [] } },
    :cluster_name => cluster_name,
    :cluster_role => cluster_role,
  }.deep_merge(Settings)
  node_settings.delete :pools
  raise "Please define the '#{cluster_name}' cluster and the '#{cluster_role}' role in your poolparty.yaml" if (Settings[:pools][cluster_name].blank? || Settings[:pools][cluster_name][cluster_role].blank?)
  node_settings = node_settings.deep_merge(
    Settings[:pools][cluster_name][:common]      ||{ }).deep_merge(
    Settings[:pools][cluster_name][cluster_role] ||{ })
  configure_aws_region node_settings
  node_settings
end

# Takes the template file and has Erubis cram the given variables in it
def erubis_template template_filename, *args
  require 'erubis'
  template   = Erubis::Eruby.new File.read(template_filename)
  text       = template.result *args
  text
end

# Reads the validation key in directly from a file
def get_chef_validation_key settings
  chef_settings  = settings[:user_data] or return
  validation_key_file = File.expand_path(chef_settings[:validation_key_file])
  return unless File.exists?(validation_key_file)
  chef_settings[:validation_key] ||= File.read(validation_key_file)
end

#
# Pass a json hash of settings into the
#
# This should be the last thing in the cloud definition, as other methods might
# populate it with data
def user_data_is_json_hash settings, debug=false
  user_data_hash = settings[:user_data]
  puts "*****\n\n#{JSON.pretty_generate(user_data_hash)}\n**********\n" if debug
  user_data user_data_hash.to_json
end

# This should be the last thing in the cloud definition, as other methods might
# populate it with data
def user_data_is_bootstrap_script settings, script_name, debug=false
  script_text = bootstrap_chef_script(script_name, settings)
  puts "*****\n\n#{script_text}\n**********\n" if debug
  user_data(script_text)
end

# Generate a shell script suitable for user-data -- bootstraps a client or
# server as appropriate
def bootstrap_chef_script role, settings
  erubis_template(
    File.dirname(__FILE__)+"/../config/user_data_script-#{role}.sh.erb",
    :public_ip        => settings[:elastic_ip],
    :hostname         => settings[:user_data][:attributes][:node_name],
    :chef_server_fqdn => settings[:user_data][:chef_server].gsub(%r{http://(.*):\d+},'\1'),
    :ubuntu_version   => 'lucid',
    :bootstrap_scripts_url_base => settings[:bootstrap_scripts_url_base],
    :chef_config      => settings[:user_data]
    )
end

# add a role to the node's run_list.
def has_role settings, role, make_security_group=nil
  security_group role if make_security_group
  settings[:user_data][:attributes][:run_list] << "role[#{role}]"
end

# Add a recipe to the node's run list.
def has_recipe settings, recipe
  settings[:user_data][:attributes][:run_list] << recipe
end
