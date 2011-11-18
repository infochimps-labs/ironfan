#
# Cookbook Name::       hbase
# Description::         Cron job to backup tables to S3
# Recipe::              backup_tables
# Author::              Chris Howe - Infochimps, Inc
#
# Copyright 2011, Chris Howe - Infochimps, Inc
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

include_recipe "hbase"

template_variables = {
    :backup_tables   => node[:hbase][:weekly_backup_tables],
    :backup_location => node[:hbase][:backup_location]
}

template "/etc/cron.weekly/backup_hbase_tables" do
  source "export_hbase_tables.rb.erb"
  mode "0744"
  variables( template_variables )
end

