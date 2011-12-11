#
# Author:: Philip (flip) Kromer for Infochimps.org
# Cookbook Name:: metachef
# Library:: node_utils
#
# Description::
#
# Copyright 2011, Infochimps, Inc
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
  #
  # Useful methods for node metadata:
  # * best guess for node's private interface / public interface
  # * force-save node if changed
  #
  module NodeUtils
    module_function # call NodeUtils.foo, or include and call #foo

    #
    # Public / Private interface best-guessing
    #

    # The local-only ip address for the given server
    def private_ip_of(server)
      server[:cloud][:private_ips].first rescue server[:ipaddress]
    end

    # The local-only ip address for the given server
    def private_hostname_of(server)
      server[:fqdn]
    end

    # The globally-accessable ip address for the given server
    def public_ip_of(server)
      server[:cloud][:public_ips].first  rescue server[:ipaddress]
    end

    #
    # Attribute helpers
    #

    # A compact timestamp, to record when services are registered
    def self.timestamp
      Time.now.utc.strftime("%Y%m%d%H%M%SZ")
    end

    #
    # Saving node
    #

    def node_changed!
      @node_changed = true
    end

    def node_changed?
      !! @node_changed
    end

    MIN_VERSION_FOR_SAVE = "0.8.0" unless defined?(MIN_VERSION_FOR_SAVE)

    # Save the node, unless we're in chef-solo mode (or an ancient version)
    def save_node!(node)
      return unless node_changed?
      # taken from ebs_volume cookbook
      if Chef::VERSION !~ /^0\.[1-8]\b/
        if not Chef::Config.solo
          Chef::Log.info('Saving Node!!!!')
          node.save
        else
          Chef::Log.warn("Skipping node save since we are running under chef-solo.  Node attributes will not be persisted.")
        end
      else
        Chef::Log.warn("Skipping node save: Chef version #{Chef::VERSION} (prior to #{MIN_VERSION_FOR_SAVE}) can't save");
      end
    end

  end
end
