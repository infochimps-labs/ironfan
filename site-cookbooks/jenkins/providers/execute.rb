#
# Cookbook Name:: jenkins
# Based on hudson
# Provider:: execute
#
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright:: 2010, VMware, Inc.
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

#pruned Chef::Provider::Execute + optional `block' param

include Chef::Mixin::Command

def action_run
  args = {
    :command => @new_resource.command,
    :command_string => @new_resource.to_s,
  }
  args[:only_if] = @new_resource.only_if if @new_resource.only_if
  args[:not_if] = @new_resource.not_if if @new_resource.not_if
  args[:timeout] = @new_resource.timeout if @new_resource.timeout
  args[:cwd] = @new_resource.cwd if @new_resource.cwd
        
  status, stdout, stderr = output_of_command(args[:command], args)
  if status.exitstatus == 0
    @new_resource.block.call(stdout) if @new_resource.block
    @new_resource.updated_by_last_action(true)
    Chef::Log.info("Ran #{@new_resource} successfully")
  else
    command_output =  "JENKINS STDOUT: #{stdout}"
    command_output << "JENKINS STDERR: #{stderr}"
    handle_command_failures(status, command_output, args)
  end
end


