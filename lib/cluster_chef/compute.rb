module ClusterChef
  #
  # Base class allowing us to layer settings for facet over cluster
  #
  class ComputeBuilder < ClusterChef::DslObject
    attr_reader :cloud, :volumes, :chef_roles
    has_keys :name, :run_list, :bogosity
    @@role_implications ||= Mash.new

    def initialize(builder_name, attrs={})
      super(attrs)
      set :name, builder_name
      @settings[:run_list] ||= []
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
      @cloud ||= ClusterChef::Cloud::Ec2.new(self)
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

    #
    # Adds the given role to the run list, and invokes any role_implications it
    # implies (for instance, defining and applying the 'ssh' security group if
    # the 'ssh' role is applied.)
    #
    def role(role_name)
      run_list << "role[#{role_name}]"
      run_list.uniq!
      self.instance_eval(&@@role_implications[role_name]) if @@role_implications[role_name]
    end

    # Add the given recipe to the run list
    def recipe(name)
      run_list << name
      run_list.uniq!
    end

    #
    # Some roles imply aspects of the machine that have to exist at creation.
    # For instance, on an ec2 machine you may wish the 'ssh' role to imply a
    # security group explicity opening port 22.
    #
    # @param [String] role_name -- the role that triggers the block
    # @yield block will be instance_eval'd in the object that calls 'role'
    #
    def self.role_implication(name, &block)
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
