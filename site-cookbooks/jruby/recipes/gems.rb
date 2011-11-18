#
# Cookbook Name::       jruby
# Description::         Gems
# Recipe::              gems
# Author::              Jacob Perkins - Infochimps, Inc
#
# Copyright 2011, Infochimps, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# hbase-stargate
%w[json configliere gorillib erubis extlib chimps net-http-persistent i18n wukong activesupport].each do |rubygem|
  gem_package rubygem do
    gem_binary "/usr/lib/jruby/bin/chef-jgem"
  end
end
