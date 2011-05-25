#
# Cookbook Name:: jruby
# Recipe:: gems
#
# Copyright 2011, Infochimps, Inc.
#
#
# Install basic gems
#
%w[json configliere gorillib erubis extlib chimps net-http-persistent hbase-stargate i18n wukong activesupport].each do |rubygem|
  bash "install jruby version of #{rubygem}" do
    user "root"
    code <<-EOH
      jruby -S gem install --no-ri --no-rdoc #{rubygem}
      touch /usr/lib/jruby/lib/hack-installed-gem-#{rubygem}
    EOH
    creates "/usr/lib/jruby/lib/hack-installed-gem-#{rubygem}"
  end
end
