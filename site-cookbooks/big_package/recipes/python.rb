#
# Cookbook Name::       big_package
# Description::         Python
# Recipe::              python
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

package "python" do
  action :install
end

%w[
  dev mysqldb
  setuptools sqlite
  simplejson
].each do |pkg|
  package "python-#{pkg}" do
    action :install
  end
end

# ctypedbytes
# %w[
#  boto dumbo
# ].each do |pkg|
#   easy_install_package pkg do
#     action :install
#   end
# end

