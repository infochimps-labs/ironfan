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

pkgs = case node[:platform]
  when "ubuntu","debian"          then [ "ruby#{node[:ruby][:version]}", "ruby#{node[:ruby][:version]}-dev", "ri#{node[:ruby][:version]}" ]
  when "centos","redhat","fedora" then %w[ ruby ruby-libs ruby-devel ruby-docs ruby-ri ruby-irb ruby-rdoc ruby-mode ]
  end

Chef::Log.debug [ node[:ruby] ].inspect + "\n\n!!!\n\n"

gem_pkgs = %w[
   extlib fastercsv json yajl-ruby libxml-ruby htmlentities addressable
   configliere right_aws whenever
   rest-client oauth json crack cheat
   echoe jeweler yard net-proto net-scp net-sftp net-ssh net-ssh-multi
   rails wirble
   wukong cassandra redis
   dependencies
   imw chimps
   fog
]

if node[:ruby][:version] == '1.8'
  pkgs     += %w[libonig2 libonig-dev]
  gem_pkgs += %w[oniguruma uuidtools idn ]
  if node[:lsb][:release].to_f < 10.10
    gem_pkgs += %w[ rdoc libopenssl-ruby  ]
  else
    gem_pkgs += %w[ libruby-extras ]
  end
end

pkgs.each do |pkg|
  package(pkg){ action :install }
end

gem_pkgs.each do |pkg|
  gem_package(pkg){ action :install }
end

gem_package("nokogiri"){action :install ; version "1.4.2" }
gem_package("hpricot"){ action :install ; version "0.8.2" }

