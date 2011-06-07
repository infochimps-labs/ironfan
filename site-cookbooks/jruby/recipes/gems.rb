#
# Cookbook Name:: jruby
# Recipe:: gems
#
# Copyright 2011, Infochimps, Inc.
#
#
# Install basic gems
#
%w[json configliere gorillib nokogiri erubis extlib chimps net-http-persistent hbase-stargate i18n wukong activesupport].each do |rubygem|
  gem_package rubygem do
    gem_binary "/usr/lib/jruby/bin/chef-jgem"
  end
end
