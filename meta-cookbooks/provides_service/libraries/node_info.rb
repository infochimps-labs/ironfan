#
# Author:: Philip (flip) Kromer for Infochimps.org
# Cookbook Name:: cassandra
# Recipe:: autoconf
#
# Copyright 2010, Infochimps, Inc
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

module ClusterChef
  module NodeInfo

    # given server, get address

    # The local-only ip address for the given server
    def private_ip_of server
      server[:cloud][:private_ips].first rescue server[:ipaddress]
    end

    # The local-only ip address for the given server
    def fqdn_of server
      server[:fqdn]
    end

    # The globally-accessable ip address for the given server
    def public_ip_of server
      server[:cloud][:public_ips].first  rescue server[:ipaddress]
    end

  end
end
