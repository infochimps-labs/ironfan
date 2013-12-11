$:.unshift File.expand_path('../../lib', __FILE__)
require 'chef'
require 'chef/knife'
require 'ironfan'
require 'fog'
Fog.mock!
Fog::Mock.delay = 0

require 'gorillib/pathname'

Pathname.register_paths(
  code:        File.expand_path('../..', __FILE__),
  fixtures:    [:code, 'spec', 'fixtures'],
  )

RSpec.configure do |cfg|
  def ironfan_go!
    k = Chef::Knife.new
    k.config[:config_file] = Pathname.path_to(:fixtures, 'knife/knife.rb')
    k.configure_chef
    Chef::Config.instance_eval do
      knife.merge!({
          :aws_access_key_id => 'access_key',
          :aws_secret_access_key => 'secret',
        })
      cluster_path Pathname.path_to(:fixtures).to_s
    end

    require 'ironfan'

    Ironfan.ui          = Chef::Knife::UI.new(STDOUT, STDERR, STDIN, {})
    Ironfan.chef_config = k.config
    Ironfan.cluster_path
  end
end

require 'chef_zero/server'
server = ChefZero::Server.new(port: 4000)
server.start_background

def uncreate_plugin(plugin_class, target_class)
  target_class.registry.clear
  plugin_class.instance_eval{ remove_const :BazBif }
end

class Foo
end

class MyPlugin
  include Ironfan::Plugin::Base; register_with Foo

  def self.plugin_hook(*_) end
end
