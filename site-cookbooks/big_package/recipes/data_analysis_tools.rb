#
# Cookbook Name::       big_package
# Recipe::              data_analysis_tools
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

%w[
  r-base r-base-dev
  x11-apps eog texlive-common texlive-binaries dvipng ghostscript latex
  libfreetype6 python-gtk2 python-gtk2-dev python-wxgtk2.8
].each{|pkg| package pkg }
