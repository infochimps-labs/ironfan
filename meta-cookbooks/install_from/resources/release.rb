#
# Cookbook Name:: install_from
# Resource::      release
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
  :install_with_make, :install_binaries, :install_python
  )

attribute :name,          :name_attribute => true
attribute :release_url,   :kind_of => String, :required => true

# Prefix directory -- other _dir attributes hang off this by default
attribute :prefix_root,      :kind_of => String, :default  => '/usr/local'
# Directory for the unreleased contents,   eg /usr/local/share/pig-0.8.0. Defaults to {prefix_root}/share/{basename_of_release_url}
attribute :install_dir,   :kind_of => String
# Directory as the project is referred to, eg /usr/local/share/pig. Defaults to {prefix_root}/{name}
attribute :home_dir,      :kind_of => String
# Release file name, eg /usr/local/src/pig-0.8.0.tar.gz
attribute :release_file,  :kind_of => String
# Checksum for the release file
attribute :checksum,       :kind_of => String, :default => nil
# Command to expand project
attribute :expand_cmd, :kind_of => String
# User to run as
attribute :user,          :kind_of => String, :default => 'root'
# Environment to pass on to commands
attribute :environment,   :kind_of => Hash, :default => {}
# Binaries to install. Supply a path relative to install_dir, and it will be
# symlinked to prefix_root
attribute :has_binaries,   :kind_of => Array,  :default => []


def initialize(*args)
  super
  @action ||= :install
end

def assume_defaults!
  # eg 'pig-0.8.0' and 'tar.gz' given 'http://apache.org/pig/pig-0.8.0.tar.gz'
  ::File.basename(release_url) =~ %r{^(.+?)(?:-bin)?\.(tar\.gz|tar\.bz2|zip)$}
  release_basename, release_ext = [$1, $2]

  Chef::Log.info( [self, release_basename, release_ext, self.to_hash, release_url, prefix_root ].inspect )

  @install_dir   ||= ::File.join(prefix_root, 'share', release_basename)
  @home_dir      ||= ::File.join(prefix_root, 'share', name)
  @release_file  ||= ::File.join(prefix_root, 'src', ::File.basename(release_url))
  @expand_cmd ||=
    case release_ext
    when 'tar.gz'  then 'tar xzf'
    when 'tar.bz2' then 'tar xjf'
    when 'zip' then 'unzip'
    else raise "Don't know how to expand #{release_url} which has extension '#{release_ext}'"
    end
end
