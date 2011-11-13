#
# Cookbook Name:: install_from
# Resource::      package
#
# Author:: Philip (flip) Kromer <flip@infochimps.com>
#
# Copyright 2011, Philip (flip) Kromer
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

actions( :download, :unpack, :configure, :build, :install,
  :configure_with_configure,
  :build_with_make, :build_with_ant,
  :install_with_make
  )

attribute :name,          :name_attribute => true
attribute :package_url,   :kind_of => String, :required => true

# Prefix directory -- other _dir attributes hang off this by default
attribute :root_dir,      :kind_of => String, :default  => '/usr/local'
# Directory for the unpackaged contents,   eg /usr/local/share/pig-0.8.0
attribute :install_dir,   :kind_of => String
# Directory as the project is referred to, eg /usr/local/share/pig
attribute :home_dir,      :kind_of => String
# Directory for the package file, eg /usr/local/src
attribute :package_file,  :kind_of => String
# Command to unpackage project
attribute :unpackage_cmd, :kind_of => String
# User to run as
attribute :user,          :kind_of => String, :default => 'root'

def initialize(*args)
  super
  @action ||= :install
end

def assume_defaults!
  # eg 'pig-0.8.0' and 'tar.gz' given 'http://apache.org/pig/pig-0.8.0.tar.gz'
  ::File.basename(package_url) =~ %r{^(.+?)(?:-bin)?\.(tar\.gz|tar\.bz2|zip)$}
  package_basename, package_ext = [$1, $2]

  Chef::Log.info( [self, package_basename, package_ext, self.to_hash, package_url, root_dir ].inspect )

  @install_dir   ||= ::File.join(root_dir, 'share', package_basename)
  @home_dir      ||= ::File.join(root_dir, 'share', name)
  @package_file  ||= ::File.join(root_dir, 'src', ::File.basename(package_url))
  @unpackage_cmd ||=
    case package_ext
    when 'tar.gz'  then 'tar xzf'
    when 'tar.bz2' then 'tar xjf'
    when 'zip' then 'unzip'
    else raise "Don't know how to unpackage #{package_url} which has extension '#{package_ext}'"
    end
end
