require 'rspec'

CLUSTER_CHEF_DIR = File.expand_path(File.dirname(__FILE__)+'/..') unless defined?(CLUSTER_CHEF_DIR)
def CLUSTER_CHEF_DIR(*paths) File.join(CLUSTER_CHEF_DIR, *paths); end

require 'chef/node'
require 'chef/resource_collection'
require 'chef/providers'
require 'chef/resources'
require 'chef/mixin/params_validate'

Dir[CLUSTER_CHEF_DIR("spec/spec_helper/*.rb")].each {|f| require f}

# Configure rspec
RSpec.configure do |config|
end
