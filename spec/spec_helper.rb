if ENV['IRONFAN_COV']
  require 'simplecov'
  SimpleCov.start
end

require 'ironfan'
require 'chef/cluster_knife'
require 'fog'
Fog.mock!
Fog::Mock.delay = 0

require 'gorillib/pathname'

Pathname.register_paths(code:     File.expand_path('../..', __FILE__),
                        spec:     [:code, 'spec'],
                        fixtures: [:spec, 'fixtures'],
                        support:  [:spec, 'support'],
                        features: [:spec, 'acceptance'],
                        steps:    [:features, 'steps'])

Dir[Pathname.path_to(:support).join('**/*.rb')].each{ |f| require f }
Dir[Pathname.path_to(:steps).join('**/*.rb')].each{ |f| require f }

RSpec.configure do |cfg|
  def ironfan_go!
    k = Chef::Knife.new
    k.config[:config_file] = Pathname.path_to(:fixtures, 'knife/knife.rb').to_s
    k.configure_chef
    Chef::Config.instance_eval do
      knife.merge!(aws_access_key_id:     'access_key',
                   aws_secret_access_key: 'secret')
      cluster_path Pathname.path_to(:fixtures).to_s
    end

    Ironfan.ui          = Chef::Knife::UI.new(STDOUT, STDERR, STDIN, {})
    Ironfan.knife_config = k.config
  end
end

require 'chef_zero/server'
server = ChefZero::Server.new(port: 4000)
server.start_background
