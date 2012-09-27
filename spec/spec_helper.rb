$:.unshift File.expand_path('../../lib', __FILE__)
require 'chef'
require 'chef/knife'
require 'fog'

Fog.mock!
Fog::Mock.delay = 0
