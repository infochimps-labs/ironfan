$:.unshift File.expand_path('../../lib', __FILE__)
require 'chef'
require 'chef/knife'
require 'fog'
Fog.mock!
Fog::Mock.delay = 0

require 'gorillib/pathname'

Pathname.register_paths(
  code:        File.expand_path('../..', __FILE__),
  fixtures:    [:code, 'spec', 'fixtures'],
  )

RSpec.configure do |config|
  def ironfan_go!
    Chef::Knife.new.configure_chef
    Chef::Config.instance_eval do
      knife.merge!({
          :aws_access_key_id => 'access_key',
          :aws_secret_access_key => 'secret',
        })
      cluster_path Pathname.path_to(:fixtures).to_s
    end

    require 'ironfan'

    Ironfan.ui          = Chef::Knife::UI.new(STDOUT, STDERR, STDIN, {})
    Ironfan.chef_config = { :verbosity => 0 }
    Ironfan.cluster_path
  end
end
