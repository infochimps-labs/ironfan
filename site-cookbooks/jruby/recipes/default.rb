#
# Cookbook Name::       jruby
# Recipe::              default
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

bash "install_jruby_from_tarball" do
user "root"
  cwd "/tmp"
  code <<-EOH
  wget http://jruby.org.s3.amazonaws.com/downloads/1.5.6/jruby-bin-1.5.6.tar.gz
  cd /usr/local/lib
  tar -xzf /tmp/jruby-bin-1.5.6.tar.gz
  EOH
  not_if "test -d /usr/local/lib/jruby-1.5.6"
end

link "/usr/lib/jruby" do
  to "/usr/local/lib/jruby-1.5.6"
end

%w[ jruby jrubyc jruby.rb jirb ].each do |file|
  link "/usr/bin/#{file}" do
    to "/usr/lib/jruby/bin/#{file}"
  end
end

cookbook_file "/usr/lib/jruby/bin/chef-jgem" do
  source "chef-jgem"
  owner "root"
  mode "0755"
end
