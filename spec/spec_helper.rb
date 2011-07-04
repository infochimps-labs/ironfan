require 'spork'
require 'rspec'

CLUSTER_CHEF_DIR = File.expand_path(File.dirname(__FILE__)+'/..') unless defined?(CLUSTER_CHEF_DIR)
def CLUSTER_CHEF_DIR(*paths) File.join(CLUSTER_CHEF_DIR, *paths); end

Spork.prefork do
  # This code is run only once when the spork server is started

  # Requires custom matchers & macros, etc from files in ./support/ & subdirs
  Dir[CLUSTER_CHEF_DIR("spec/support/**/*.rb")].each {|f| require f}

  # Configure rspec
  RSpec.configure do |config|
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
end
