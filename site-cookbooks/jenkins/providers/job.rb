#
# Cookbook Name:: jenkins
# Based on hudson
# Provider:: job
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

def job_url
  "#{@new_resource.url}/job/#{@new_resource.job_name}/config.xml"
end

def new_job_url
  "#{@new_resource.url}/createItem?name=#{@new_resource.job_name}"
end

def job_exists
  url = URI.parse(job_url)
  res = Chef::REST::RESTRequest.new(:GET, url, nil).call
  Chef::Log.debug("[jenkins_job] GET #{url.request_uri} == #{res.code}")
  res.kind_of?(Net::HTTPSuccess)
end

def post_job(url)
  #shame we can't use http_request resource
  url = URI.parse(url)
  Chef::Log.debug("[jenkins_job] POST #{url.request_uri} using #{@new_resource.config}")
  body = IO.read(@new_resource.config)
  headers = {"Content-Type" => "text/xml"}
  res = Chef::REST::RESTRequest.new(:POST, url, body, headers).call
  res.error! unless res.kind_of?(Net::HTTPSuccess)
end

#could also use: jenkins_cli "create-job #{@new_resource.job_name} < #{@new_resource.config}"
def action_create
  unless job_exists
    post_job(new_job_url)
  end
end

#there is no cli update-job command
def action_update
  if job_exists
    post_job(job_url)
  else
    post_job(new_job_url)
  end
end

def action_delete
  jenkins_cli "delete-job #{@new_resource.job_name}"
end

def action_disable
  jenkins_cli "disable-job #{@new_resource.job_name}"
end

def action_enable
  jenkins_cli "enable-job #{@new_resource.job_name}"
end

def action_build
  jenkins_cli "build #{@new_resource.job_name}"
end
