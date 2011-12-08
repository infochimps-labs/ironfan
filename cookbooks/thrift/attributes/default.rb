#
# Cookbook Name:: thrift
# Attributes:: default
#
# Copyright 2011, Opscode, Inc.
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

default[:thrift][:home_dir]            = "/usr/local/bin/thrift"

default[:thrift][:version]           = '0.8.0'
default[:thrift][:release_url]       = ':apache_mirror:/:name:/:version:/:name:-:version:.tar.gz'
default[:thrift][:checksum]          = '1bed1ea17bf31c861fa8dd6e0182360eb8234383f32d0e4a36b70047b2e6b313'

default[:thrift][:configure_options] = []
