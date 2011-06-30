module ClusterChef
  #
  # Base class allowing us to layer settings for facet over cluster
  #
  class ComputeBuilder < ClusterChef::DslObject
    attr_reader :cloud
    has_keys :name, :chef_attributes, :roles, :run_list, :cloud
    @@role_implications ||= {}

    def initialize builder_name
      super()
      name         builder_name
      run_list     []
      @settings[:chef_attributes] = {}
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
    def cloud cloud_provider=nil, &block
      raise "Only have ec2 so far" if cloud_provider && (cloud_provider != :ec2)
      @cloud ||= ClusterChef::Cloud::Ec2.new
      @cloud.instance_eval(&block) if block
      @cloud
    end

    # Merges the given hash into
    # FIXME: needs to be a deep_merge
    def chef_attributes hsh={}
      # The DSL attribute for 'chef_attributes' merges not overwrites
      @settings[:chef_attributes].merge! hsh unless hsh.empty? #.blank?
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

    #
    # This is an outright kludge, awaiting a refactoring of the
    # securit group bullshit
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
        self.cloud.security_group(cluster_name+"-george") do
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
 
    def create_servers
      delegate_to_servers( :create_server )
    end

    def uncreated_servers
      # Return the collection of servers that are not yet 'created'
      return ClusterSlice.new cluster, servers.reject { |svr| svr.fog_server }
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

    def display headings = ["Node","Facet","Index","Chef?","AWS ID","State","Address"]
      sorted_servers = servers.sort{ |a,b| (a.facet_name <=> b.facet_name) *9 + (a.facet_index.to_i <=> b.facet_index.to_i)*3 + (a.facet_index <=> b.facet_index) }
      if block_given?
        defined_data = sorted_servers.map {|svr| yield svr }
      else
        defined_data = sorted_servers.map do |svr|
          x = { "Node"    => svr.chef_node_name,
            "Facet"   => svr.facet_name,
            "Index"   => svr.facet_index,
            "Chef?"   => svr.chef_node ? "yes" : "[red]no[reset]",
          }
          if svr.fog_server
            x["AWS ID"]  = svr.fog_server.id
            x["State"]   = svr.fog_server.state
            x["Address"] = svr.fog_server.public_ip_address
          else
            x["State"] = "not running"
          end
          x
        end
      end

      if defined_data.empty?
        puts "Nothing to report"
      else
        Formatador.display_compact_table(defined_data,headings)
      end

    end

  end

  #
  # A cluster has many facets. Any setting applied here is merged with the facet
  # at resolve time; if the facet explicitly sets any attributes they will win out.
  #
  class Cluster < ClusterChef::ComputeBuilder
    attr_reader :facets, :undefined_servers
    has_keys :cluster_role
    
    def initialize clname
      super(clname)
      @facets = {}
      chef_attributes  :cluster_name => clname
      cluster_role "#{clname}_cluster"
    end

    def facet facet_name, &block
      @facets[facet_name] ||= ClusterChef::Facet.new(self, facet_name)
      @facets[facet_name].instance_eval(&block) if block
      @facets[facet_name]
    end
    
    def has_facet? facet_name
      return @facets.member?(facet_name)
    end

    def slice *args
      return self if args.length == 0
      facet_name = args.shift      
      unless @facets[facet_name] 
        $stderr.puts "Facet '#{facet_name}' is not defined in cluster '#{cluster_name}'"
        exit -1
      end
      return @facets[facet_name].slice *args
    end

    def cluster
      self
    end

    def cluster_name
      self.name
    end

    def use *clusters
      clusters.each do |c|
        cluster = c.to_s
        ClusterChef.load_cluster(cluster)
        merge! cluster
      end
      self
    end


    def merge! other_cluster
      if(other_cluster.is_a?(String)) then other_cluster = ClusterChef.cluster(other_cluster) end
      @settings = other_cluster.to_hash.merge @settings
      @settings[:run_list]        = other_cluster.run_list + self.run_list
      @settings[:chef_attributes] = other_cluster.chef_attributes.merge(self.chef_attributes)
      cloud.merge! other_cluster.cloud
      self
    end


    def security_groups
      groups = cloud.security_groups
      @facets.values.each { |f| groups.merge f.security_groups }
      return groups
    end

    def resolve!
      @facets.values.each { |f| f.resolve! }
      
      discover!
    end

    def servers
      @facets.values.map {|facet| facet.servers }.flatten
    end

    def cluster_group
      return cluster_name
    end

    def fog_servers
      @fog_servers ||= ClusterChef.servers.select {|s| s.groups.index( cluster_group ) && s.state != "terminated" }
    end

    def chef_nodes
      return @chef_nodes if @chef_nodes
      @chef_nodes = []
      Chef::Search::Query.new.search(:node,"cluster_name:#{cluster_name}") do |n|
        next if n.nil? or n.cluster_name != cluster_name
        @chef_nodes.push n unless n.nil?
      end
      @chef_nodes
    end

    def discover!
      # Build a crossover table between what should be, what is in fog
      # and what is in chef.
      node_name_hash = Hash.new { |hash,key| hash[key] = [nil,nil,nil] }
      servers.each { |s|
        node_name_hash[ s.chef_node_name ][0] = s
      }
      
      # The only way to link up to an actual instance is throug
      # what Ohai discovered about the node in chef, so we need
      # to build an instance_id to node_name map

      aws_instance_hash = {}
      chef_nodes.each do |n|
        node_name_hash[ n.node_name ][1] = n
        aws_instance_hash[ n.ec2.instance_id ] = n.node_name if n.ec2.instance_id
      end
    
      fog_servers.each do |s|
        # If the fog server is tagged with cluster/facet/index, then try
        # to locate the corresponding machine in the cluster def and get
        # its chef_node_name
        if s.tags["cluster"] && s.tags["facet"] && s.tags["index"] 
          if has_facet?( s.tags["facet"]) 
            f = facet(s.tags["facet"])
            if f.has_server?( s.tags["index"] ) 
              nn = f.server(s.tags["index"]).chef_node_name
            end
          end
        end

        # Otherwise, try to get to it through mapping the aws instance id
        # to the chef node name found in the chef node
        nn ||= aws_instance_hash[ s.id ] || s.id
        
        node_name_hash[ nn ][2] = s
      end
       
      @undefined_servers = []
      node_name_hash.values.each do |svr,chef_node,fog_svr|
        if svr
          # Note that it is possible that either one of these could be
          # nil. If fog_svr is nil and chef_node is defined, it means
          # that the actual instance has been terminated, but that it
          # did probably exist at one time. When we go to launch the 
          # cluster, this node will be rebuilt.

          # If the fog_server is defined, but the chef node is not,
          # it means that someone has started the node but chef has
          # not managed to set things up yet. It also means that someone
          # has worked out a way to map a fog_server to a specific
          # facet_index.
          svr.chef_node = chef_node
          svr.fog_server = fog_svr
        else
          # If we are here, we have discovered some nodes that belong
          # to the cluster but are not actually defined implictly or
          # explicitly by the cluster definition. We could probably
          # try to work out what facet and index they are supposed to
          # be, but I am not sure that it is useful. Instead, we will
          # just collect them into one big bag and we can deal with
          # them as needed later on.
          @undefined_servers.push( { :chef_node => chef_node, :fog_server => fog_svr } )
        end
      end
    end
  end


  # This class represents a loose collection of servers within a cluster, but not necessarily
  # all in the same facet.  They can be started, stopped, launched, killed, etcetera as a group.
  class ClusterSlice < ClusterChef::ComputeBuilder
    attr_reader :cluster    

    def initialize cluster, servers
      @cluster = cluster
      @servers = servers
    end

    def servers
      @servers
    end
    
    def cluster_name
      cluster.name
    end

  end


  class Facet < ClusterChef::ComputeBuilder
    attr_reader :cluster, :facet_name
    has_keys  :instances, :facet_role

    def initialize cluster, fct_name
      super(facet_name)
      @cluster = cluster
      @facet_name = fct_name
      @servers = {}
      chef_attributes :cluster_role       => facet_name # backwards compatibility
      chef_attributes :facet_name         => facet_name

      facet_role      "#{@cluster.name}_#{facet_name}"
    end

    def slice *args
      return self if args.length == 0
      slice = FacetSlice.new self, *args
      
      return slice
    end

    def servers
      @servers.values
    end

    def server_by_index index
      @servers[index.to_s]
    end

    def get_node_name index
      "#{cluster_name}-#{facet_name}-#{index}"
    end
    
    def cluster_name
      cluster.name
    end

    def security_groups
      groups = cloud.security_groups
      @servers.values.each { |s| groups.merge s.security_groups }
      return groups
    end

    #
    # Resolve:
    #
    def resolve!
      clname = @cluster.name
      @settings    = @cluster.to_hash.merge @settings
      cloud.resolve!          @cluster.cloud
      cloud.keypair           clname if cloud.keypair.nil? #.blank?
      cloud.security_group    clname do authorize_group clname end
      cloud.security_group    "#{clname}-#{facet_name}"
      
      role cluster.cluster_role if cluster.cluster_role
      role self.facet_role if self.facet_role
      
      @settings[:run_list]        = @cluster.run_list + self.run_list
      @settings[:chef_attributes] = @cluster.chef_attributes.merge(self.chef_attributes)
      chef_attributes :run_list => run_list
      chef_attributes :aws => { :access_key => Chef::Config[:knife][:aws_access_key_id], :secret_access_key => Chef::Config[:knife][:aws_secret_access_key],}
      # Generate server definitions if they have not already been created
      resolve_servers!
      self
      
    end

    def to_hash_with_cloud
      to_hash.merge({ :cloud => cloud.to_hash, })
    end

    def resolve_servers!
      # Create facets not explicitly defined
      instances.times do |index| 
        facet_index = index.to_s

        server facet_index unless @servers[facet_index]
      end

      servers.each do |s|
        s.resolve!
      end
    end

    def server index, &block
      facet_index = index.to_s
      @servers[facet_index] ||= ClusterChef::Server.new(self, facet_index)
      @servers[facet_index].instance_eval(&block) if block
      @servers[facet_index]
    end

    def has_server? index
      return @servers.member? index.to_s
    end

    def cluster_group
      return "#{cluster_name}-#{facet_name}"
    end

  end

  
  class FacetSlice < ClusterChef::ComputeBuilder
    attr_reader :cluster, :facet
    has_keys  :instances, 

    def initialize facet, instance_indexes
      @facet = facet
      @cluster = facet.cluster
      @instance_indexes = instance_indexes
    end

    def parse_indexes
      indexes = []

      @instance_indexes.split(",").each do |term|
        if term =~ /(\d+)-(\d+)/
          $1.to_i.upto($2.to_i) do |i|
            indexes.push i.to_s
          end
        else
          indexes.push term
        end
      end
      indexes.sort!.uniq!
      

      @servers = {}
      indexes.each do |idx|
        @servers[idx] = facet.server_by_index idx
      end

    end

    def servers
      parse_indexes unless @servers
      @servers.values
    end

    def server_by_index index
      parse_indexes unless @servers
      @servers[index.to_s]
    end

    def get_node_name index
      "#{cluster_name}-#{facet_name}-#{index}"
    end
    
    def cluster_name
      cluster.name
    end

    def security_groups
      cluster.security_groups
    end


    def to_hash_with_cloud
      to_hash.merge({ :cloud => cloud.to_hash, })
    end

    def resolve_servers!
      facet.resolve_servers!
    end

    def server index, &block
      parse_indexes unless @servers

      facet_index = index.to_s
      @servers[facet_index] ||= ClusterChef::Server.new(self, facet_index)
      @servers[facet_index].instance_eval(&block) if block
      @servers[facet_index]
    end

  end


  class Server < ClusterChef::ComputeBuilder
    attr_reader :cluster, :facet, :facet_index
    attr_accessor :chef_node, :fog_server
    has_keys :chef_node_name, :instances, :facet_name

    def initialize facet, index
      super facet.get_node_name( index )
      @facet_index = index
      @facet = facet
      @cluster = facet.cluster

      @settings[:facet_name] = @facet.facet_name
      
      @settings[:chef_node_name] = name
      chef_attributes :node_name => name
      chef_attributes :cluster_role_index => index
      chef_attributes :facet_index => index

      @tags = { "cluster" => cluster_name,
                "facet"   => facet_name,
                "index"   => facet_index }

      @volumes = []

    end

    def cluster_name
      cluster.name
    end

    def security_groups
      groups = cloud.security_groups
    end

    def tag key,value=nil
      return @tags[key] unless value
      @tags[key] = value
    end
    
    def servers
      return [self]
    end

    def volume specs
      # specs should be a hash of the following form
      # { :id          =>  "vol-xxxxxxxx",   # the id of the volume to attach
      #   :device      => "/dev/sdq",        # the device to attach to
      # }
      @volumes.push specs
    end
    #
    # Resolve:
    #
    def resolve!
      clname = @cluster.name
      facetname = @facet.name
      
      @settings    = @facet.to_hash.merge @settings

      cloud.resolve!          @facet.cloud
      #cloud.keypair           clname unless cloud.keypair
      #cloud.security_group    clname do authorize_group clname end
      #cloud.security_group "#{clname}-#{self.name}"

      @settings[:run_list]        = @facet.run_list + self.run_list
      @settings[:chef_attributes] = @facet.chef_attributes.merge(self.chef_attributes)

      chef_attributes :run_list => run_list
      chef_attributes :aws => { :access_key => Chef::Config[:knife][:aws_access_key_id], :secret_access_key => Chef::Config[:knife][:aws_secret_access_key],}
      chef_attributes :cluster_chef => { 
        :cluster => cluster_name,
        :facet => facet_name,
        :index => facet_index,
      }
      chef_attributes :node_name => chef_node_name

      self
    end

    # FIXME: a lot of AWS logic in here. This probably lives in the facet.cloud
    # but for the one or two things that come from the facet
    def create_server
      # only create a server if it does not already exist
      return nil if fog_server

      @fog_server = ClusterChef.connection.servers.create(
        :image_id          => cloud.image_id,
        :flavor_id         => cloud.flavor,
        #
        :groups            => cloud.security_groups.keys,
        :key_name          => cloud.keypair,
        # Fog does not actually create tags when it creates a server.                                                          
        :tags              => 
          { :cluster => cluster_name,
            :facet =>   facet_name,
            :index =>   facet_index,
          },
        :user_data         => JSON.pretty_generate(cloud.user_data.merge(:attributes => chef_attributes)),
        # :block_device_mapping => [],
        # :disable_api_termination => disable_api_termination,
        # :instance_initiated_shutdown_behavior => instance_initiated_shutdown_behavior,
        :availability_zone => cloud.availability_zones.first
        )
    end

    def create_tags
      tags = { "cluster" => cluster_name,
        "facet"   => facet_name,
        "index"   => facet_index, }
      tags.each_pair do |key,value|
        ClusterChef.connection.tags.create(:key => key, 
                                           :value => value,
                                           :resource_id => fog_server.id)
      end
    end

    def attach_volumes
      @volumes.each do |vol_spec|
        id = vol_spec[:id]
        next unless id
        volume = ClusterChef.connection.volumes.select{|v| v.id == id }[0]
        next unless volume
        volume.device = vol_spec[:device]
        volume.server = fog_server
      end
    end

    def to_hash_with_cloud
      to_hash.merge({ :cloud => cloud.to_hash, })
    end

  end
end
