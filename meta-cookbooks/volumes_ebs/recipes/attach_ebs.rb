#
# Cookbook Name::       ec2
# Description::         Attach EBS volumes as directed by node[:volumes]
# Recipe::              attach_ebs
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

include_recipe "aws"

aws  = mntvol_aws_credentials

if aws
  attachable_volumes(:ebs).each do |vol_name, vol|

    aws_ebs_volume "attach ebs volume #{vol.inspect}" do
      provider              "aws_ebs_volume"
      aws_access_key        aws[:aws_access_key_id]
      aws_secret_access_key aws[:aws_secret_access_key]
      aws_region            aws[:aws_region]
      availability_zone     aws[:availability_zone]
      volume_id             vol['volume_id']
      device                vol['device']
      action                :attach
    end

  end
end
