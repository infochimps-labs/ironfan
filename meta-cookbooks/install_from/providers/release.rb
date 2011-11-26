#
# Cookbook Name:: install_from
# Provider::      install_from_release
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

#
# Does the fetch-unpack-configure-build-install dance.
#
# Given a project 'pig', with url 'http://apache.org/pig/pig-0.8.0.tar.gz', and
# the default :prefix_root of '/usr/local', this provider will
#
# * fetch  it to :release_file ('/usr/local/src/pig-0.8.0.tar.gz')
# * unpack it to :install_dir  ('/usr/local/share/pig-0.8.0')
# * create a symlink for :home_dir ('/usr/local/share/pig') pointing to :install_dir
# * configure the project
# * build the project
# * install the project,

action :download do
  new_resource.assume_defaults!
  directory(::File.dirname(new_resource.release_file)) do
    mode        '0755'
    action      :create
    recursive   true
  end

  remote_file new_resource.release_file do
    source      new_resource.release_url
    mode        "0644"
    action      :create
    checksum    new_resource.checksum if new_resource.checksum
    not_if{     ::File.exists?(new_resource.release_file) }
  end
end

action :unpack do
  action_download
  directory(::File.dirname(new_resource.install_dir)) do
    mode      '0755'
    action    :create
    recursive true
  end

  bash "unpack #{new_resource.name} release" do
    user        new_resource.user
    cwd         ::File.dirname(new_resource.install_dir)
    code        new_resource.expand_cmd
    creates     new_resource.install_dir
    environment new_resource.environment
  end

  link new_resource.home_dir do
    to          new_resource.install_dir
    action      :create
  end
end

action :configure do
  action_unpack
end

action :build do
  action_configure
end

action :install do
  action_build
  action_install_binaries
end

action :build_with_ant do
  action_build
  bash "build #{new_resource.name} with ant" do
    user        new_resource.user
    cwd         new_resource.install_dir
    code        "ant"
    environment new_resource.environment
  end
end

action :configure_with_autoconf do
  action_configure
  bash "configure #{new_resource.name} with configure" do
    user        new_resource.user
    cwd         new_resource.install_dir
    code        "./configure #{new_resource.autoconf_opts.join(' ')}"
    environment new_resource.environment
    not_if{     ::File.exists?(::File.join(new_resource.install_dir, 'config.status')) }
  end
end

action :build_with_make do
  action_build
  bash "build #{new_resource.name} with make" do
    user        new_resource.user
    cwd         new_resource.install_dir
    code        "make"
    environment new_resource.environment
  end
end

action :install_binaries do
  new_resource.has_binaries.each do |bin|
    link ::File.join(new_resource.prefix_root, 'bin', ::File.basename(bin)) do
      to        ::File.join(new_resource.home_dir, bin)
      action    :create
    end
  end
end

action :install_python do
  action_install

  bash "install #{new_resource.name} with python" do
    command "python setup.py install"
    cwd           new_resource.install_dir
  end
end

action :install_with_make do
  action_build_with_make
  action_install
  bash "install #{new_resource.name} with make" do
    user        new_resource.user
    cwd         new_resource.install_dir
    code        "make install"
    environment new_resource.environment
  end
end
