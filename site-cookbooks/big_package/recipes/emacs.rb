#
# Cookbook Name::       big_package
# Description::         Emacs
# Recipe::              emacs
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

package "emacs23-nox" do
  action :upgrade
end

# erlang-mode php-mode mmm-mode css-mode html-helper-mode lua-mode
[
  "python-mode", "ruby#{node[:ruby][:version]}-elisp", "org-mode",
].each do |pkg|
  package pkg do
    action :upgrade
  end

end

# to install your own: SOMETHING LIKE THIS
#   directory "/usr/local/share/emacs/site-lisp" do
#     action :create
#     owner 'group'
#     mode 0775
#     recursive true
#   end

#   cookbook_file "/usr/local/share/emacs/site-lisp/pig-mode.el" do
#     source "pig-mode.el"
#     owner 'group'
#     mode 0664
#     action :create
#   end
