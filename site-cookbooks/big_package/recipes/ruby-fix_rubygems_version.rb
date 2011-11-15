#
# Cookbook Name::       big_package
# Description::         Ruby Fix Rubygems Version
# Recipe::              ruby-fix_rubygems_version
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2011, Philip (flip) Kromer - Infochimps, Inc
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

Chef::Log.debug [ node[:ruby] ].inspect + "\n\n!!!\n\n"

rubygems_target_version = "1.6.2"
bash "update rubygems to = #{rubygems_target_version}" do
  code %Q{
    gem install --no-rdoc --no-ri rubygems-update --version=#{rubygems_target_version}
    update_rubygems --version=#{rubygems_target_version}
  }
  not_if{ `gem --version`.chomp >= rubygems_target_version }
end

cookbook_file "/tmp/fuck_you_rubygems.diff" do
  owner   "root"
  group   "root"
  mode    "0644"
  source  "fuck_you_rubygems.diff"
  action  :create
end
