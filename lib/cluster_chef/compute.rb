module ClusterChef
  #
  # Base class allowing us to layer settings for facet over cluster
  #
  class ComputeBuilder < ClusterChef::DslObject
    attr_reader :cloud, :volumes, :chef_roles
    has_keys :name, :chef_attributes, :run_list, :cloud, :bogosity
    @@role_implications ||= Mash.new

    def initialize(builder_name, attrs={})
      super(attrs)
      set :name, builder_name
      @settings[:run_list]        ||= []
      @settings[:chef_attributes] ||= {}
      @volumes = Mash.new
    end

    # set the bogosity to a descriptive reason. Anything truthy implies bogusness
    def bogus?
      !! self.bogosity
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
    def cloud(cloud_provider=nil, attrs={}, &block)
      raise "Only have ec2 so far" if cloud_provider && (cloud_provider != :ec2)
      @cloud ||= ClusterChef::Cloud::Ec2.new
      @cloud.configure(attrs, &block)
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
    # @param attrs [Hash] a hash of attributes to pass down.
    #
    def volume(volume_name, attrs={}, &block)
      volumes[volume_name] ||= ClusterChef::Volume.new(:parent => self, :name => volume_name)
      volumes[volume_name].configure(attrs, &block)
      volumes[volume_name]
    end

    def root_volume(attrs={}, &block)
      volume(:root, attrs, &block)
    end

    # FIXME: this should be in cloud, and should be done right.
    def mounts_ephemeral_volumes
      # Bring the ephemeral storage (local scratch disks) online
      volume(:ephemeral0) do device '/dev/sdb'; volume_id 'ephemeral0' ; end
      volume(:ephemeral1) do device '/dev/sdc'; volume_id 'ephemeral1' ; end
      volume(:ephemeral2) do device '/dev/sdd'; volume_id 'ephemeral2' ; end
      volume(:ephemeral3) do device '/dev/sde'; volume_id 'ephemeral3' ; end
    end

    # Delegates to the (cluster/facet)_role's +Chef::Role#override_attributes+ method
    # @param [Hash] hsh the attributes to set
    def override_attributes(hsh)
      main_role.override_attributes(hsh)
    end

    # Delegates to the (cluster/facet)_role's +Chef::Role#default_attributes+ method
    # @param [Hash] hsh the attributes to set
    def default_attributes(hsh)
      main_role.default_attributes(hsh)
    end

    # Adds the given role to the run list, and invokes any role_implications it
    # implies (for instance, the 'ssh' role on an ec2 machine requires port 22
    # be explicity opened.)
    #
    def role(role_name)
      run_list << "role[#{role_name}]"
      run_list.uniq!
      @settings[:run_list] << "role[#{role_name}]"
      self.instance_eval(&@@role_implications[role_name]) if @@role_implications[role_name]
    end

    # Add the given recipe to the run list
    def recipe(name)
      run_list << name
      run_list.uniq!
    end

    # Some roles imply aspects of the machine that have to exist at creation.
    # For instance, on an ec2 machine you may wish the 'ssh' role to imply a
    # security group explicity opening port 22.
    #
    def self.role_implication name, &block
      @@role_implications[name] = block
    end

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

    role_implication "web_server" do
      self.cloud.security_group("http_server") do
        authorize_port_range  80..80
        authorize_port_range 443..443
      end
    end

  end
end
