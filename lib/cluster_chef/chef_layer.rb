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
      step("  setting node runlist")
      chef_node.run_list = Chef::RunList.new(*@settings[:run_list])
    end

    def save_chef_node
      step("  saving chef node", :green)
      chef_node.save
    end

    def delete_chef
      if chef_node   then chef_node.destroy   ; @chef_node   = nil ; end
      if chef_client then chef_client.destroy ; @chef_client = nil ; end
    end

    def chef_client
      return @chef_client unless @chef_client.nil?
      @chef_client = handle_chef_response(@chef_client, '404') do
        Chef::ApiClient.load( fullname )
      end
    end

    def chef_node
      return @chef_node unless @chef_node.nil?
      @chef_node = handle_chef_response(@chef_node, '404') do
        Chef::Node.load( fullname )
      end
    end

    # true if chef client is created and discovered
    def chef_client?
      !! @chef_client
    end

    # true if chef node is created and discovered
    def chef_node?
      !! @chef_node
    end

    #
    # OK so things get a little fishy here, and it's all Opscode's fault ;-)
    #
    # There's currently no API for setting ACLs. However, if the *client the
    # node will run as* is the *client that creates the node*, it is granted the
    # correct permissions.
    #
    # * client exists, node exists: don't need to do anything. We trust that permissions are correct.
    # * client absent, node exists: client created, node is fine. We trust that permissions are correct.
    # * client absent, node absent: client created, so have key; client creates node, so it has write permissions.
    # * client exists, node absent: FAIL.
    #
    # The current implementation persists the client keys locally to your
    # Chef::Config[:keypair_path].  This is insecure and unmanageable; and the
    # node will shortly re-register the key, making it invalide anyway.
    #
    # If the client's private_key is empty/wrong and the node is absent, it will
    # cause an error. in that case, you can:
    #
    # * create the node yourself in the management console, and
    #   grant access to its eponymous client; OR
    # * nuke the client key from orbit (it's the only way to be sure) and re-run,
    #   taking all responsibility for the catastrophic results of an errant nuke; OR
    # * wait for opscode to open API access for ACLs.
    #
    #

    def ensure_chef_client
      step("  ensuring chef client exists")
      return @chef_client if chef_client
      @chef_client = Chef::ApiClient.new
      @chef_client.name(fullname)
      @chef_client.admin(false)
      #
      handle_chef_response(@chef_client, '409') do
        step( "    creating chef #{@chef_client}" )
        # ApiClient#create sends extra params that fail -- we'll do it ourselves
        response = Chef::REST.new(Chef::Config[:chef_server_url]).post_rest(
          "clients", { 'name' => fullname, 'admin' => false, 'private_key' => true })
        @chef_client.private_key(response['private_key'])
        cloud.user_data(:client_key => @chef_client.private_key)
        write_client_key
      end
      @chef_client
    end

    def ensure_chef_node
      step("  ensuring chef node exists")
      return @chef_node if chef_node
      @chef_node = Chef::Node.new
      @chef_node.name(fullname)
      @chef_node.override[:cluster_name] = cluster_name
      @chef_node.override[:facet_name]   = facet_name
      @chef_node.override[:facet_index]  = facet_index
      #
      err_message = "You've found yourself in a situation where the #{fullname} client exists, \nbut you don't have access to its client key. \nYou need to either fix its permissions in the Chef console, or (if you are aware of the terrible consequences) do \nknife client delete #{fullname}"
      response = handle_chef_response(@chef_node, '409') do
        unless File.exists?(client_key_filename)
          ui.warn "Cannot create chef node #{fullname} -- no client key found in #{client_key_filename}."
          raise(err_message)
        end
        chef_server_rest = Chef::REST.new(Chef::Config[:chef_server_url], fullname, client_key_filename)
        begin
          ui.info("    creating chef #{@chef_node}")
          chef_server_rest.post_rest('nodes', @chef_node)
        rescue Net::HTTPServerException => e
          if e.response.code == '401'
            ui.warn "Cannot create chef node #{fullname} -- client key #{client_key_filename} no longer valid."
            ui.warn(err_message)
          end
          raise
        end
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
      step("  ensuring chef node permissions are correct")
      chef_server_rest = Chef::REST.new(Chef::Config[:chef_server_url])
      perms = chef_server_rest.get_rest("nodes/#{fullname}/_acl")
      perms_valid = {}
      REQUIRED_PERMISSIONS.each{|perm| perms_valid[perm] = perms[perm] && perms[perm]['actors'].include?(fullname) }
      Chef::Log.debug("Checking permissions: #{perms_valid.inspect} -- #{ perms_valid.values.all? ? 'correct' : 'BADNESS' }")
      unless perms_valid.values.all?
        ui.info(" ************************ ")
        ui.info(" ")
        ui.info(" INCONSISTENT PERMISSIONS for node #{fullname}:")
        ui.info("   The client[#{fullname}] should have permissions for #{REQUIRED_PERMISSIONS.join(', ')}")
        ui.info("   Instead, they are #{perms_valid.inspect}")
        ui.info("   You should create the node #{fullname} as client[#{fullname}], not as yourself.")
        ui.info(" ")
        ui.info("   Please adjust the permissions on the Opscode console, at")
        ui.info("     https://manage.opscode.com/nodes/#{fullname}/_acl")
        ui.info(" ")
        ui.info(" ************************ ")
      end
    end

    def client_key
      return unless chef_client
      @client_key ||= (chef_client.private_key || read_client_key)
    end

    def chef_client_script_content
      return @chef_client_script_content if @chef_client_script_content
      return unless cloud.chef_client_script
      script_filename = File.expand_path(cloud.chef_client_script, File.join(Chef::Config[:cluster_chef_path], 'config'))
      @chef_client_script_content = safely{ File.read(script_filename) }
    end

  protected

    def client_key_filename
      File.join(Chef::Config.keypair_path, "client-#{fullname}.pem")
    end
    def write_client_key
      ui.info( "    writing #{@chef_client}' private key to #{client_key_filename}" )
      File.open(client_key_filename, "w"){|f| f.print( @chef_client.private_key ) }
    end
    def read_client_key
      return unless File.exists?(client_key_filename)
      key = File.read(client_key_filename).chomp
      @chef_client.private_key(key)
      cloud.user_data(:client_key => key)
      key
    end

    # Execute the given chef call, but don't explode if the given http status
    # code comes back
    #
    # @return chef object, or false if the server returned a recoverable response
    def handle_chef_response(action, recoverable_responses, &block)
      begin
        block.call
      rescue Net::HTTPServerException => e
        raise unless Array(recoverable_responses).include?(e.response.code)
        Chef::Log.debug("Swallowing a #{e.response.code} response in #{self.fullname}: #{e}")
        return false
      end
    end

  end
end
