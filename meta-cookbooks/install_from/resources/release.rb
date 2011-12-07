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

actions(
  :download,
  :unpack,
  :configure,
  :build,
  :install,
  :configure_with_autoconf,
  :build_with_make,
  :build_with_ant,
  :install_with_make,
  :install_binaries,
  :install_python
  )

attribute :name,          :name_attribute => true

# URL for the tarball/zip file to install from. If it is named something like
# pig-0.8.0.tar.gz and unpacks to ./pig-0.8.0 we can take it from there
# You may use the following recognized patterns:
#   :name:          -- value of resource's name
#   :version:       -- value of resource's version
#   :apache_mirror: -- node[:install_from][:apache_mirror]
#
attribute :release_url,   :kind_of => String, :required => true

# Prefix directory -- other _dir attributes hang off this by default
attribute :prefix_root,   :kind_of => String, :default  => '/usr/local'

# version slug, appended to the name to get the install_dir
attribute :version,       :kind_of => String, :required => true

# Directory for the unreleased contents,   eg /usr/local/share/pig-0.8.0. default: {prefix_root}/share/{name}-#{version}
attribute :install_dir,   :kind_of => String

# Directory as the project is referred to, eg /usr/local/share/pig. default: {prefix_root}/share/{name}
attribute :home_dir,      :kind_of => String

# Checksum for the release file
attribute :checksum,      :kind_of => String, :default => nil

# Command to expand project
attribute :expand_cmd,    :kind_of => String

# Release file name, eg /usr/local/src/pig-0.8.0.tar.gz
attribute :release_file,  :kind_of => String

# Release file extension, if we can't guess it from the release file: one of 'tar.gz', 'tar.bz2' or 'zip'
attribute :release_ext,   :kind_of => String

# User to run as
attribute :user,          :kind_of => String, :default => 'root'

# Environment to pass on to commands
attribute :environment,   :kind_of => Hash, :default => {}

# Binaries to install. Supply a path relative to install_dir, and it will be
# symlinked to prefix_root
attribute :has_binaries,  :kind_of => Array,  :default => []

# options to pass to the ./configure command for the configure_with_autoconf action
attribute :autoconf_opts, :kind_of => Array, :default => []

def initialize(*args)
  super
  @action ||= :install
end

def assume_defaults!
  #
  set_release_url
  # the release_url 'http://apache.org/pig/pig-0.8.0.tar.gz' has
  # release_basename 'pig-0.8.0' and release_ext 'tar.gz'
  release_basename = ::File.basename(release_url.gsub(/\?.*\z/, '')).gsub(/-bin\b/, '')
  release_basename =~ %r{^(.+?)\.(tar\.gz|tar\.bz2|zip)}
  @release_ext      ||= $2

  @home_dir         ||= ::File.join(prefix_root, 'share', name)
  @install_dir      ||= ::File.join(prefix_root, 'share', "#{name}-#{version}")
  @release_file     ||= ::File.join(prefix_root, 'src',   "#{name}-#{version}.#{release_ext}")
  @expand_cmd ||=
    case release_ext
    when 'tar.gz'  then untar_cmd('xzf', release_file, install_dir)
    when 'tar.bz2' then untar_cmd('xjf', release_file, install_dir)
    when 'zip'     then "unzip -q -u -o '#{release_file}'"
    else raise "Don't know how to expand #{release_url} which has extension '#{release_ext}'"
    end

  # Chef::Log.info( [environment, install_dir, home_dir, release_file, release_basename, release_ext, release_url, prefix_root ].inspect )
end

def untar_cmd(sub_cmd, release_file, install_dir)
  %Q{mkdir -p '#{install_dir}' ; tar #{sub_cmd} '#{release_file}' --strip-components=1 -C '#{install_dir}'}
end

def set_release_url
  raise "Missing required resource attribute release_url" unless @release_url
  @release_url.gsub!(/:name:/,          name.to_s)
  @release_url.gsub!(/:version:/,       version.to_s)
  @release_url.gsub!(/:apache_mirror:/, node['install_from']['apache_mirror'])
end
