module Ironfan
  module Provider
    module Ec2

      # 
      # Resources
      #
      class Instance < Ironfan::Provider::Instance
        delegate :_dump, :addresses, :ami_launch_index, :ami_launch_index=, :architecture, 
            :architecture=, :attributes, :availability_zone, :availability_zone=, 
            :block_device_mapping, :block_device_mapping=, :client_token, :client_token=, 
            :collection, :collection=, :connection, :connection=, :console_output, 
            :created_at, :created_at=, :destroy, :dns_name, :dns_name=, :dup_attributes!, 
            :flavor, :flavor=, :flavor_id, :flavor_id=, :groups, :groups=, 
            :iam_instance_profile, :iam_instance_profile=, :iam_instance_profile_arn=, 
            :iam_instance_profile_name=, :id, :id=, :identity, :identity=, :image_id, 
            :image_id=, :instance_initiated_shutdown_behavior, 
            :instance_initiated_shutdown_behavior=, :ip_address, :kernel_id, :kernel_id=, 
            :key_name, :key_name=, :key_pair, :key_pair=, :merge_attributes, 
            :missing_attributes, :monitor=, :monitoring, :monitoring=, :network_interfaces, 
            :network_interfaces=, :new_record?, :password, :password=, :placement_group, 
            :placement_group=, :platform, :platform=, :private_dns_name, :private_dns_name=, 
            :private_ip_address, :private_ip_address=, :private_key, :private_key=, 
            :private_key_path, :private_key_path=, :product_codes, :product_codes=, 
            :public_ip_address, :public_ip_address=, :public_key, :public_key=, 
            :public_key_path, :public_key_path=, :ramdisk_id, :ramdisk_id=, :ready?, 
            :reason, :reason=, :reboot, :reload, :requires, :requires_one, 
            :root_device_name, :root_device_name=, :root_device_type, :root_device_type=, 
            :save, :scp, :scp_download, :scp_upload, :security_group_ids, :security_group_ids=, 
            :setup, :ssh, :ssh_port, :sshable?, :start, :state, :state=, :state_reason, 
            :state_reason=, :stop, :subnet_id, :subnet_id=, :symbolize_keys, :tags, :tags=, 
            :tenancy, :tenancy=, :user_data, :user_data=, :username, :username=, :volumes, 
            :vpc_id, :vpc_id=, :wait_for,
          :to => :adaptee
        def name()
          tags["Name"] || tags["name"]
        end

        def matches?(machine)
          id == machine.remembered.ec2.instance_id && \
            name == machine.expected.full_name
        end

        def display_values(style,values={})
          # style == :minimal
          values["State"] =             state.to_sym
          values["InstanceID"] =        id
          values["Public IP"] =         public_ip_address
          values["Private IP"] =        private_ip_address
          values["Created On"] =        created_at.to_date
          return values if style == :minimal

          # style == :default
          values["Flavor"] =            flavor_id
          values["AZ"] =                availability_zone
          return values if style == :default

          # style == :expanded
          values["Image"] =             image_id
          values["Volumes"] =           volumes.map(&:id).join(', ')
          values["SSH Key"] =           key_name
          values
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
        field :adaptee, Whatever

        def initialize(*args,&block)
          super(*args,&block)
          self.adaptee = Fog::Compute.new({
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
          adaptee.servers.each do |fs| 
            instances << Instance.new(:adaptee => fs) unless fs.blank?
          end
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