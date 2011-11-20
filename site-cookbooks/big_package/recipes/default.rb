#
# Cookbook Name::       big_package
# Description::         Base configuration for big_package
# Recipe::              default
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

%w[
  git-core cvs subversion exuberant-ctags tree zip liblzo2-dev
  libpcre3-dev libbz2-dev libidn11-dev libxml2-dev libxml2-utils libxslt1-dev libevent-dev
  ant openssl colordiff ack htop makepasswd sysstat
  g++ python-setuptools python-dev
  s3cmd
  tidy
  ifstat
  nmap chkconfig tree emacs23-nox elinks
].each do |pkg|
  package pkg
end

%w[
   extlib rails fastercsv json yajl-ruby
   addressable fog cheat configliere wukong gorillib
   pry
].each do |gem_pkg|
  gem_package gem_pkg do
    action :install
  end
end
