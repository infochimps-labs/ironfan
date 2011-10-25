#
# Cookbook Name:: ruby
# Recipe:: default
#
# Copyright 2008-2009, Opscode, Inc.
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

# !!!!!
#
# Please do not add the following gems to this file. They break on one
# version of ruby or the other.  You should instead use an .rvmrc and Gemfile
# (bundler) to install them specifically for your program.
#
# oniguruma nokogiri libruby-extras uuidtools idn hpricot nokogiri echoe
# goliath ruby-debug19 [anything with 19 or 18 in it]
#

%w[
   rspec rspec-rails spork watchr pry
   rest-client oauth crack jeweler yard
   htmlentities right_aws libxml-ruby
   wirble awesome_print
   net-proto net-scp net-sftp net-ssh net-ssh-multi
].each do |pkg|
  gem_package(pkg){ action :install }
end
