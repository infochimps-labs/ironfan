#
# Cookbook Name::       Rstats
# Description::         Installs the base R package, a ruby interface, and some basic R packages.
# Recipe::              default
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

package 'r-base'
package 'r-base-dev'

gem_package "rsruby" do
  options "-- --with-R-dir=#{node[:rstats][:home_dir]} --with-R-lib=/usr/lib/R --with-R-include=/usr/share/R/include"
  action :install
end


# Once R is installed you'll want to install some essential packages like VGAM and ggplot, ie. install.packages('VGAM')
bash "Installing r packages" do
  code %Q{ export R_HOME=/usr/lib/R ; echo 'install.packages(c("VGAM", "ggplot2"))' | Rscript --verbose - }
end
