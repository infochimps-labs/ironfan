#
# Cookbook Name::       pig
# Description::         Compiles the Piggybank, a library of useful functions for pig
# Recipe::              piggybank
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

package "sun-java6-jdk"
package "sun-java6-bin"
package "sun-java6-jre"

package "ivy"

bash 'build piggybank' do
  user        'root'
  cwd         "#{node[:pig][:home_dir]}/contrib/piggybank/java"
  environment 'JAVA_HOME' => node[:pig][:java_home]
  code        'ant'
  not_if{ File.exists?("#{node[:pig][:home_dir]}/contrib/piggybank/java/piggybank.jar") }
end
