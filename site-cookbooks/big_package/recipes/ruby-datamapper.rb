#
# Cookbook Name::       big_package
# Recipe::              ruby-datamapper
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
dm-adjust
dm-aggregates
dm-ar-finders
dm-cli
dm-constraints
dm-core
dm-couchdb-adapter
dm-ferret-adapter
dm-is-list
dm-is-nested_set
dm-is-remixable
dm-is-searchable
dm-is-state_machine
dm-is-tree
dm-is-versioned
dm-is-viewable
dm-migrations
dm-more
dm-observer
dm-querizer
dm-rest-adapter
dm-serializer
dm-shorthand
dm-sweatshop
dm-tags
dm-timestamps
dm-types
dm-validations
do_mysql
do_sqlite3
mysql
].each do |pkg|

  gem_package(pkg){ action :install }

end

