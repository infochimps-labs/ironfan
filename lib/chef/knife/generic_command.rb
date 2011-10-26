#
# Author:: Philip (flip) Kromer (<flip@infochimps.com>)
# Copyright:: Copyright (c) 2011 Infochimps, Inc
# License:: Apache License, Version 2.0
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

require File.expand_path(File.dirname(__FILE__)+"/knife_common.rb")

module ClusterChef
  class Script < Chef::Knife
    include ClusterChef::KnifeCommon

    deps do
      ClusterChef::KnifeCommon.load_deps
    end

    option :dry_run,
      :long        => "--dry-run",
      :description => "Don't really run, just use mock calls",
      :boolean     => true,
      :default     => false

    def run
      load_cluster_chef
      die(banner) if @name_args.empty?
      configure_dry_run

      target = get_slice_where(slice_criterion, *@name_args)

      die('', "No nodes to #{sub_command}, exiting", 1) if target.empty?

      puts
      puts "About to run #{sub_command} on the following servers:"
      display(target)
      puts
      confirm_execution(target)
      #
      perform_execution(target)
      puts
      puts "Finished!"
      puts
      display(target)
    end

    def perform_execution(target)
      puts "Running #{sub_command}:"
      target.send(sub_command)
    end
  end
end
