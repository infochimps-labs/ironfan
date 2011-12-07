#
# Cookbook Name::       elasticsearch
# Description::         load_balancer
# Recipe::              load_balancer
# Author::              GoTime, modifications by Infochimps
#
# Copyright 2011, GoTime, modifications by Infochimps
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

# TODO: Check to make sure this doesn't depend on the obselete nginx front-end setup
load_balancer   node[:elasticsearch][:load_balancer] if node[:elasticsearch][:load_balancer]
