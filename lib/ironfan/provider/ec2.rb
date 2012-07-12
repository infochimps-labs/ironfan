module Ironfan
  module Provider
    module Ec2

      # 
      # Resources
      #
      class Instance < Ironfan::Provider::Instance
        def name()
          native.tags["Name"] || native.tags["name"]
        end

        def matches?(machine)
          native.id == machine.chef_node.native.ec2.instance_id && \
            name == machine.expectation.full_name
        end
      end

      class EbsVolume < Ironfan::Provider::Resource
      end

      class SecurityGroup < Ironfan::Provider::Resource
      end

      class KeyPair < Ironfan::Provider::Resource
      end

      class PlacementGroup < Ironfan::Provider::Resource
      end

      # 
      # Connection
      #
      class Connection < Ironfan::Provider::IaasConnection
        field :native, Whatever

        def initialize(*args,&block)
          super(*args,&block)
          self.native = Fog::Compute.new({
            :provider              => 'AWS',
            :aws_access_key_id     => Chef::Config[:knife][:aws_access_key_id],
            :aws_secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
            :region                => Chef::Config[:knife][:region]
          })
        end

        def discover!(cluster)
          discover_instances! cluster
          #discover_ebs_volumes!
            # Walk the list of servers, asking each to discover its volumes.
          #discover_security_groups!
          #discover_key_pairs!
          #discover_placement_groups!
        end
        
        def discover_instances!(cluster)
          return instances unless instances.empty?
          native.servers.each {|fs| instances << Instance.new(fs) unless fs.blank? }
          instances
        end
        
        # An instance matches if the Name tag starts with the selector's full_name
        def instances_of(selector)
          instances.values.select {|i| i.name.match("^#{selector.full_name}") }
        end
      end

    end
  end
end