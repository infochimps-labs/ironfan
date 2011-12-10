require 'rubygems' unless defined?(Gem)
require 'bundler'
# begin
#   Bundler.setup(:default, :development)
# rescue Bundler::BundlerError => e
#   $stderr.puts e.message
#   $stderr.puts "Run `bundle install` to install missing gems"
#   exit e.status_code
# end
require 'spork'

unless defined?(CLUSTER_CHEF_DIR)
  CLUSTER_CHEF_DIR = File.expand_path(File.dirname(__FILE__)+'/..')
  def CLUSTER_CHEF_DIR(*paths) File.join(CLUSTER_CHEF_DIR, *paths); end
  # load from vendored libraries, if present
  Dir[CLUSTER_CHEF_DIR("vendor/*/lib")].each{|dir| p dir ;  $LOAD_PATH.unshift(File.expand_path(dir)) } ; $LOAD_PATH.uniq!
end

Spork.prefork do # This code is run only once when the spork server is started

  require 'rspec'
  require 'chef'
  require 'chef/knife'
  require 'fog'

  Fog.mock!
  Fog::Mock.delay = 0

  CHEF_CONFIG_FILE = File.expand_path(CLUSTER_CHEF_DIR('spec/test_config.rb')) unless defined?(CHEF_CONFIG_FILE)
  Chef::Config.from_file(CHEF_CONFIG_FILE)

  # Requires custom matchers & macros, etc from files in ./spec_helper/
  Dir[CLUSTER_CHEF_DIR("spec/spec_helper/*.rb")].each {|f| require f}

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
