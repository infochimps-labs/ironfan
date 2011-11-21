#
# Author:: Philip (flip) Kromer (<flip@infochimps.com>)
# Cookbook Name:: rstats
# Attribute::     default
#
# Copyright 2011, Infochimps, Inc
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

default[:rstats][:home_dir]  = '/usr/lib/R'
default[:rstats][:conf_dir]  = '/etc/R'

default[:rstats][:r_packages] = %w[ r-cran-VGAM r-cran-rggobi  ] # r-cran-ggplot2

default[:rstats][:cran_mirror_url] = "http://cran.stat.ucla.edu"
# default[:rstats][:cran_mirror_url] = "http://watson.nci.nih.gov/cran_mirror/"
# default[:rstats][:cran_mirror_url] = "http://cran.us.r-project.org"
