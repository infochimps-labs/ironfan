require 'spork'
require 'rspec'


Spork.prefork do
  # This code is run only once when the spork server is started
  CLUSTER_CHEF_DIR = File.expand_path(File.dirname(__FILE__)+'/..') unless defined?(CLUSTER_CHEF_DIR)
  def CLUSTER_CHEF_DIR(*paths) File.join(CLUSTER_CHEF_DIR, *paths); end

  require 'chef'
  require 'fog'

  Fog.mock!
  Fog::Mock.delay = 0

  CHEF_CONFIG_FILE = File.expand_path(CLUSTER_CHEF_DIR('spec/test_config.rb')) unless defined?(CHEF_CONFIG_FILE)
  Chef::Config.from_file(CHEF_CONFIG_FILE)

  # Requires custom matchers & macros, etc from files in ./support/ & subdirs
  Dir[CLUSTER_CHEF_DIR("spec/support/**/*.rb")].each {|f| require f}

  def load_example_cluster(name)
    require(CLUSTER_CHEF_DIR('clusters', "#{name}.rb"))
  end
  def get_example_cluster name
    load_example_cluster(name)
    ClusterChef.cluster(name)
  end

  # Configure rspec
  RSpec.configure do |config|
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
end
