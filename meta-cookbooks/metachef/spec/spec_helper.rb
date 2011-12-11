require 'rspec'

METACHEF_DIR = File.expand_path(File.dirname(__FILE__)+'/..') unless defined?(METACHEF_DIR)
def METACHEF_DIR(*paths) File.join(METACHEF_DIR, *paths); end

require 'chef/node'
require 'chef/resource_collection'
require 'chef/providers'
require 'chef/resources'
require 'chef/mixin/params_validate'

class Chef
  class Resource

    def self.json_create(o)
      resource = self.new(o["instance_vars"]["name"])
      o["instance_vars"].each do |k,v|
        resource.instance_variable_set("@#{k}".to_sym, v)
      end
      resource
    end
  end
end


Dir[METACHEF_DIR("spec/spec_helper/*.rb")].each {|f| require f}

# Configure rspec
RSpec.configure do |config|
end
