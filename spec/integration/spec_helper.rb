this_dir = File.realpath(File.dirname(__FILE__))

$:.unshift File.expand_path('../../lib', this_dir)
require 'chef'
require 'chef/knife'
require 'fog'

ENV['KNIFE_HOME'] = File.expand_path('minimal-chef-repo/knife', this_dir)
ENV['CHEF_USER']  = 'ironfantester'
Chef::Knife.new.configure_chef

require 'ironfan'
Ironfan.ui          = Chef::Knife::UI.new(STDOUT, STDERR, STDIN, {})
Ironfan.chef_config = { :verbosity => 0 }

Dir.glob(File.expand_path('spec_helper/*.rb', this_dir)).each { |file| load(file) }
