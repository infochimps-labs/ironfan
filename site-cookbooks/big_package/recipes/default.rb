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

# override_attributes({
#     :package_sets => {
#       :install => %w[ base dev sysadmin ec2 text ],
#       :sets => {
#         :base      => {
#           :pkgs      => %w[ tree git-core zip openssl libbz2-dev libpcre3-dev libevent-dev ], },
#         :dev       => {
#           :pkgs      => %w[ emacs23-nox elinks colordiff ack exuberant-ctags ],
#           :gems      => %w[ rails extlib json yajl-ruby addressable cheat configliere wukong gorillib pry ] },
#         :sysadmin  => {
#           :pkgs      => %w[ ifstat htop tree chkconfig sysstat htop nmap ], },
#         :ec2       => {
#           :pkgs      => %w[ s3cmd ],
#           :gems      => %w[ fog   ], },
#         :text      => {
#           :pkgs      => %w[ libidn11-dev libxml2-dev libxml2-utils libxslt1-dev tidy ], },
#       }
#     }
#   })
#
# node[:package_sets][:install]           = [:base, :dev, :sysadmin, :ec2, :text]
# node[:package_sets][:sets][:ec2][:pkgs] = [
#   's3cmd',
#   { :name => 'ec2-ami-tools', :version => '1.3.49953-0ubuntu3' },
#   { :name => 'ec2-ami-tools', :version => '1.3.57419-0ubuntu3' },  ]
# node[:package_sets][:sets][:ec2]        = {
#   :gems => %w[ fog right_aws ],
#   :pkgs => [
#     's3cmd',
#     { :name => 'ec2-ami-tools', :version => '1.3.49953-0ubuntu3' },
#     { :name => 'ec2-ami-tools', :version => '1.3.57419-0ubuntu3' }, ]
#   }
#
#
# override_attributes({
#     :package_sets => {
#       :install    => %w[ base dev sysadmin ec2 text ],
#       #
#       :pkgs => {
#         :base     => %w[ tree git-core zip openssl libbz2-dev libpcre3-dev libevent-dev ],
#         :dev      => %w[ emacs23-nox elinks colordiff ack exuberant-ctags ],
#         :sysadmin => %w[ ifstat htop tree chkconfig sysstat htop nmap ],
#         :ec2      => %w[ s3cmd ec2-ami-tools ec2-api-tools ],
#         :text     => %w[ libidn11-dev libxml2-dev libxml2-utils libxslt1-dev tidy ],
#       },
#       #
#       :gems => {
#         :dev      => %w[ rails extlib json yajl-ruby addressable cheat configliere wukong gorillib pry ] },
#       :ec2        => %w[ fog  right_aws ],
#     },
#   })
#
# node[:package_sets][:install]    = [:base, :dev, :sysadmin, :ec2, :text]
# node[:package_sets][:pkgs][:ec2] = [
#   's3cmd',
#   { :name => 'ec2-ami-tools', :version => '1.3.49953-0ubuntu3' },
#   { :name => 'ec2-ami-tools', :version => '1.3.57419-0ubuntu3' },  ]
# node[:package_sets][:gems][:ec2] = %w[ fog ]


# node['big_package']['pkg_sets'].each do |pkg_set_name, pkgs|
#
#   pkgs.each do |pkg|
#     pkg = { :name => pkg } if pkg.is_a?(String)
#     package pkg[:name] do
#       version   pkg[:version] if pkg[:version]
#       source    pkg[:source]  if pkg[:source]
#       options   pkg[:options] if pkg[:options]
#       action    pkg[:action] || :install
#     end
#   end
#
# end
