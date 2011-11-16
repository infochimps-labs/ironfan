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
    #   cloud do
    #     image_name     'maverick'
    #     security_group :nagios
    #   end
    #
    #   # defines ec2-specific behavior
    #   cloud(:ec2) do
    #     public_ip      '1.2.3.4'
    #     region         'us-east-1d'
    #   end
    #
    def cloud(cloud_provider=nil, attrs={}, &block)
      raise "Only have ec2 so far" if cloud_provider && (cloud_provider != :ec2)
      @cloud ||= ClusterChef::Cloud::Ec2.new(self)
      @cloud.configure(attrs, &block)
      @cloud
    end

    # sugar for cloud(:ec2)
    def ec2(attrs={}, &block)
      cloud(:ec2, attrs, &block)
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
      run_list << name.to_s
      run_list.uniq!
    end

  end
end
