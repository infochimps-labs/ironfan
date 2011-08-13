#
# Cookbook Name:: benchmarkable
# Recipe:: default
#
# Copyright 2011, Infochimps
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

# http://download2.berlios.de/hardinfo/hardinfo-0.5.1.tar.bz2
package 'hardinfo'

package 'lmbench'
package 'apache2-utils'
# echo -e "\n\n430\n\nyes\n\n\n\n\n/mnt/tmp\n\nno\n" | sudo lmbench-run
# sudo apt-get install apache2-utils
