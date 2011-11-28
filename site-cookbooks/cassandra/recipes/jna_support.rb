#
# Cookbook Name::       cassandra
# Description::         Jna Support
# Recipe::              jna_support
# Author::              Benjamin Black
#
# Copyright 2011, Benjamin Black
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

# XXX: Only supports Ubuntu x86_64
if node[:platform].downcase == "ubuntu" && node[:kernel][:machine] == "x86_64"
  bash "install_libjna-java" do
    dlfile = "libjna-java_amd64.deb"
    user        "root"
    cwd         "/tmp"
    code        %Q{wget -q -O #{dlfile} #{node[:cassandra][:jna_deb_amd64_url]} && dpkg -i #{dlfile}}
    not_if      "dpkg -s libjna-java | egrep '^Status: .* installed' > /dev/null"
  end

  # Link into our cassandra directory
  link "#{node[:cassandra][:home_dir]}/lib/jna.jar" do
    to          "/usr/share/java/jna.jar"
    notifies    :restart, "service[cassandra]", :delayed if startable?(node[:cassandra])
  end
else
  Chef::Log.warn("JNA cookbook not supported on this platform")
end
