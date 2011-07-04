module ClusterChef
  #
  # Base class allowing us to layer settings for facet over cluster
  #
  class ComputeBuilder < ClusterChef::DslObject
    attr_reader :cloud, :volumes
    has_keys :name, :chef_attributes, :roles, :run_list, :cloud
    @@role_implications ||= Mash.new

    def initialize builder_name, attrs={}
      super(attrs)
      set :name, builder_name
      @settings[:run_list]        ||= []
      @settings[:chef_attributes] ||= {}
      @volumes = Mash.new
    end

    # Magic method to produce cloud instance:
    # * returns the cloud instance, creating it if necessary.
    # * executes the block in the cloud's object context
    #
    # @example
    #   # defines a security group
    #   cloud :ec2 do
    #     security_group :foo
    #   end
    #
    # @example
    #   # same effect
    #   cloud.security_group :foo
    #
    def cloud cloud_provider=nil, hsh={}, &block
      raise "Only have ec2 so far" if cloud_provider && (cloud_provider != :ec2)
      @cloud ||= ClusterChef::Cloud::Ec2.new
      @cloud.configure(hsh, &block) if block
      @cloud
    end

    # Magic method to describe a volume
    # * returns the named volume, creating it if necessary.
    # * executes the block (if any) in the volume's context
    #
    # @example
    #   # a 1 GB volume at '/data' from the given snapshot
    #   volume(:data) do
    #     size        1
    #     mount_point '/data'
    #     snapshot_id 'snap-12345'
    #   end
    #
    # @param volume_name [String] an arbitrary handle -- you can use the device
    #   name, or a descriptive symbol.
    # @param hsh [Hash] a hash of attributes to pass down.
    #
    def volume volume_name, hsh={}, &block
      vol = (volumes[volume_name] ||= ClusterChef::Volume.new(:parent => self))
      vol.configure(hsh, &block)
      vol
    end

    # Merges the given hash into
    # FIXME: needs to be a deep_merge
    def chef_attributes hsh={}
      @settings[:chef_attributes].merge! hsh unless hsh.empty?
      @settings[:chef_attributes]
    end

    # Adds the given role to the run list, and invokes any role_implications it
    # implies (for instance, the 'ssh' role on an ec2 machine requires port 22
    # be explicity opened.)
    #
    def role role_name
      run_list << "role[#{role_name}]"
      self.instance_eval(&@@role_implications[role_name]) if @@role_implications[role_name]
    end

    # Add the given recipe to the run list
    def recipe name
      run_list << name
    end

    # Some roles imply aspects of the machine that have to exist at creation.
    # For instance, on an ec2 machine you may wish the 'ssh' role to imply a
    # security group explicity opening port 22.
    #
    # FIXME: This feels like it should be done at resolve time
    #
    def role_implication name, &block
      @@role_implications[name] = block
    end

    def resolve_volumes!
      if backing == 'ebs'
        # Bring the ephemeral storage (local scratch disks) online
        volume(:ephemeral0, :device => '/dev/sdc', :volume_id => 'ephemeral0')
        volume(:ephemeral1, :device => '/dev/sdd', :volume_id => 'ephemeral1')
        volume(:ephemeral2, :device => '/dev/sde', :volume_id => 'ephemeral2')
        volume(:ephemeral3, :device => '/dev/sdf', :volume_id => 'ephemeral3')
      end
    end

    #
    # This is an outright kludge, awaiting a refactoring of the
    # security group bullshit
    #
    def setup_role_implications
      role_implication "hadoop_master" do
        self.cloud.security_group 'hadoop_namenode' do
          authorize_port_range 80..80
        end
      end

      role_implication "nfs_server" do
        self.cloud.security_group "nfs_server" do
          authorize_group "nfs_client"
        end
      end

      role_implication "nfs_client" do
        self.cloud.security_group "nfs_client"
      end

      role_implication "ssh" do
        self.cloud.security_group 'ssh' do
          authorize_port_range 22..22
        end
      end

      role_implication "chef_server" do
        self.cloud.security_group "chef_server" do
          authorize_port_range 4000..4000  # chef-server-api
          authorize_port_range 4040..4040  # chef-server-webui
        end
      end

      role_implication("george") do
        self.cloud.security_group("#{cluster_name}-george") do
          authorize_port_range  80..80
          authorize_port_range 443..443
        end
      end
    end

    # These are some helper methods for iterating through the servers
    # to do things

    def delegate_to_servers method, threaded = false
      # If we are not threading, sequentially call the method for each server
      # and return the results in an array
      return servers.map {|svr| svr.send(method) } unless threaded

      # Create threads to send a message to the servers in parallel
      threads = servers.map {|svr| Thread.new(svr) { |s| s.send(method) } }

      # Wait for the threads to finish and return the array of results
      return threads.map {|t| t.join.value }
    end

    def delegate_to_fog_servers method
      servers.map do |svr|
        svr.fog_server.send(method) if svr.fog_server
      end
    end

    # Here are a few

    def start
      delegate_to_fog_servers( :start  )
      delegate_to_fog_servers( :reload  )
    end

    def stop
      delegate_to_fog_servers( :stop )
      delegate_to_fog_servers( :reload  )
    end

    def destroy
      delegate_to_fog_servers( :destroy )
      delegate_to_fog_servers( :reload  )
    end

    def reload
      delegate_to_fog_servers( :reload  )
    end

    def delete_chef( delete_clients = true, delete_nodes = true)
      servers.each do |svr|
        next unless svr.chef_node
        node = svr.chef_node
        node.destroy
        svr.chef_node = nil
      end
    end

    def create_servers
      delegate_to_servers( :create_server )
    end

    def uncreated_servers
      # Return the collection of servers that are not yet 'created'
      return ClusterSlice.new cluster, servers.reject{|svr| svr.fog_server }
    end

    # This is a generic display routine for cluster-like sets of nodes. If you call
    # it with no args, you get the basic table that knife cluster show draws.
    # If you give it an array of strings, you can override the order and headings
    # displayed. If you also give it a block you can supply your own logic for
    # generating content. The block is given a ClusterChef::Server instance for each
    # item in the collection and should return a hash of Name,Value pairs to display
    # in the table.
    #
    # There is an example of how to call this functon with a block in knife/cluster_launch.rb

    def display headings = ["Name", "Chef?", "InstanceID", "State", "Public IP", "Created At"]
      sorted_servers = servers.sort{ |a,b| (a.facet_name <=> b.facet_name) *9 + (a.facet_index.to_i <=> b.facet_index.to_i)*3 + (a.facet_index <=> b.facet_index) }
      if block_given?
        defined_data = sorted_servers.map{|svr| yield svr }
      else
        defined_data = sorted_servers.map do |svr|
          hsh = {
            "Name"    => svr.chef_node_name,
            "Facet"   => svr.facet_name,
            "Index"   => svr.facet_index,
            "Chef?"   => svr.chef_node ? "yes" : "[red]no[reset]",
          }
          if (s = svr.fog_server)
            hsh.merge!({
                "InstanceID"        => (s.id && s.id.length > 0) ? s.id : "???",
                "Flavor"            => s.flavor_id,
                "Image"             => s.image_id,
                "AZ"                => s.availability_zone,
                "SSH Key"           => s.key_name,
                "State"             => s.state,
                "Public IP"         => s.public_ip_address,
                "Private IP"        => s.private_ip_address,
                "Created At"        => s.created_at.strftime("%Y%m%d-%H%M%S"),
              })
          else
            hsh["State"] = "[red]not running[reset]"
          end
          hsh
        end
      end

      if defined_data.empty?
        puts "Nothing to report"
      else
        Formatador.display_compact_table(defined_data,headings)
      end
    end
  end
end

