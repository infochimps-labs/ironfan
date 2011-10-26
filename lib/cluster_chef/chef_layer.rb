module ClusterChef
  ComputeBuilder.class_eval do
    def new_chef_role(role_name, cluster, facet=nil)
      chef_role = Chef::Role.new
      chef_role.name        role_name
      chef_role.description "ClusterChef generated role for #{[cluster_name, facet_name].compact.join('-')}" unless chef_role.description
      chef_role.instance_eval{ @cluster = cluster; @facet = facet; }
      @chef_roles << chef_role
      chef_role
    end
  end


  #
  # ClusterChef::Server methods that handle chef actions
  #
  Server.class_eval do

    def chef_set_runlist
      chef_node.run_list = Chef::RunList.new(*@settings[:run_list])
    end

    def chef_set_attributes
      chef_attributes.each_pair do |key,value|
        next if key == :run_list
        chef_node.normal[key] = value
      end
    end

    # Execute the given chef call, but don't explode if the given http status
    # code comes back
    #
    # @return chef object, or false if the server returned a recoverable response
    def handle_chef_response(recoverable_responses, &block)
      begin
        block.call
      rescue Net::HTTPServerException => e
        raise unless Array(recoverable_responses).include?(e.response.code)
        Chef::Log.debug("Swallowing a #{e.response.code} response in #{self.fullname}: #{e}")
        false
      end
    end

    def chef_client
      return @chef_client unless @chef_client.nil?
      @chef_client = handle_chef_response('404') do
        Chef::ApiClient.load( fullname )
      end
    end

    # true if chef client is created and discovered
    def chef_client?
      !! @chef_client
    end

    def chef_node
      return @chef_node unless @chef_node.nil?
      @chef_node = handle_chef_response('404') do
        Chef::Node.load( fullname )
      end
    end

    # true if chef node is created and discovered
    def chef_node?
      !! @chef_node
    end

    #
    # OK so things get a little fishy here, and it's all Opscode's fault ;-)
    #
    # There's currently no API for setting ACLs.
    #
    # * client exists, node exists: don't need to do anything. We trust that permissions are correct.
    # * client absent, node exists: client created, node is fine. We trust that permissions are correct.
    # * client absent, node absent: client created, so have key; client creates node, so it has write permissions.
    # * client exists, node absent: FAIL.
    #
    # We could try some workarounds -- persist the client keys locally (insecure
    # and unmanageable), force re-register the client if the node is absent
    # (catastrophic if we somehow invalidate a running server's key), others.
    #
    # Instead, if the client's private_key is blank and the node is absent, we
    # raise an error. in that case, you can:
    #
    # * create the node yourself in the management console, and
    #   grant access to its eponymous client; OR
    # * nuke the client key from orbit (it's the only way to be sure) and re-run; OR
    # * wait for opscode to open API access for ACLs.
    # 
    #

    def ensure_chef_client
      return @chef_client if chef_client

      @chef_client = Chef::ApiClient.new
      @chef_client.name(fullname)
      @chef_client.admin(false)
      handle_chef_response('409') do
        # ApiClient#create sends extra params that fail -- we'll do it ourselves
        response = Chef::REST.new(Chef::Config[:chef_server_url]).post_rest("clients", { 'name' => fullname, 'admin' => false })
        @chef_client.private_key(response['private_key'])
        Chef::Log.debug( "Created client #{@chef_client}" )
        write_client_key
      end
      @chef_client
    end

    def client_key_filename
      File.join(Chef::Config.keypair_path, "client-#{fullname}.pem")
    end
    def write_client_key
      Chef::Log.debug( "Writing client #{@chef_client} private key to #{client_key_filename}" )
      File.open(client_key_filename, "w"){|f| f.print( @chef_client.private_key ) }
    end
    def read_client_key
      return unless File.exists?(client_key_filename)
      @chef_client.private_key(File.read(client_key_filename).chomp)
    end

    def ensure_chef_node
      return @chef_node if chef_node
      @chef_node = Chef::Node.new
      @chef_node.name(fullname)
      response = handle_chef_response('409') do
        unless File.exists?(client_key_filename)
          raise "Cannot create chef node #{fullname} -- no client key found in #{client_key_filename}."
        end
        chef_server_rest = Chef::REST.new(Chef::Config[:chef_server_url], fullname, client_key_filename)
        chef_server_rest.post_rest('nodes', @chef_node)
      end
      @chef_node
    end

    # The client is required to have these permissions on its eponymous node
    REQUIRED_PERMISSIONS = %w[read create update]

    #
    # Verify that the client has required _acl's on the node.
    #
    # We don't raise an error, just a very noisy warning.
    #
    def check_node_permissions
      chef_server_rest = Chef::REST.new(Chef::Config[:chef_server_url])
      perms = chef_server_rest.get_rest("nodes/#{fullname}/_acl")
      perms_valid = {}
      REQUIRED_PERMISSIONS.each{|perm| perms_valid[perm] = perms[perm] && perms[perm]['actors'].include?(fullname) }
      Chef::Log.debug("Checking permissions: #{perms_valid.inspect} -- #{ perms_valid.values.all? ? 'correct' : 'BADNESS' }")
      unless perms_valid.values.all?
        Chef::Log.info(" ************************ ")
        Chef::Log.info(" ")
        Chef::Log.info(" INCONSISTENT PERMISSIONS for node #{fullname}:")
        Chef::Log.info("   The client[#{fullname}] should have permissions for #{REQUIRED_PERMISSIONS.join(', ')}")
        Chef::Log.info("   Instead, they are #{perms_valid.inspect}")
        Chef::Log.info("   You should create the node #{fullname} as client[#{fullname}], not as yourself.")
        Chef::Log.info(" ")
        Chef::Log.info("   Please adjust the permissions on the Opscode console, at")
        Chef::Log.info("     https://manage.opscode.com/nodes/#{fullname}/_acl")
        Chef::Log.info(" ")
        Chef::Log.info(" ************************ ")
      end
    end
  end
end
