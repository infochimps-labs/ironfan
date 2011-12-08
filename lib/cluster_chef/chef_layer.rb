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

module ClusterChef
  module DryRunnable
    # Run given block unless in dry_run mode (ClusterChef.chef_config[:dry_run]
    # is true)
    def unless_dry_run
      if ClusterChef.chef_config[:dry_run]
        ui.info("      ... but not really (#{ui.color("dry run", :bold, :yellow)} for server #{name})")
      else
        yield
      end
    end
  end

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

  ServerSlice.class_eval do
    include DryRunnable
    def sync_roles
      step("  syncing cluster and facet roles")
      unless_dry_run do
        chef_roles.each(&:save)
      end
    end
  end

  #
  # ClusterChef::Server methods that handle chef actions
  #
  Server.class_eval do
    include DryRunnable

    # The chef client, if it already exists in the server.
    # Use the 'ensure' method to create/update it.
    def chef_client
      return @chef_client unless @chef_client.nil?
      @chef_client = cluster.find_client(fullname) || false
    end

    # The chef node, if it already exists in the server.
    # Use the 'ensure' method to create/update it.
    def chef_node
      return @chef_node unless @chef_node.nil?
      @chef_node   = cluster.find_node(fullname) || false
    end

    # true if chef client is created and discovered
    def chef_client?
      chef_client.present?
    end

    # true if chef node is created and discovered
    def chef_node?
      chef_node.present?
    end

    def delete_chef
      if chef_node   then
        step("  deleting chef node", :red)
        unless_dry_run do
          chef_node.destroy
        end
        @chef_node   = nil
      end
      if chef_client
        step("  deleting chef client", :red)
        unless_dry_run do
          chef_client.destroy
        end
        @chef_client = nil
      end
    end

    # creates or updates the chef node.
    #
    # FIXME: !! this currently doesn't do the right thing for modifications to the
    #           chef node. !!
    #
    # See notes at top of file for why all this jiggery-fuckery
    #
    # * client exists, node exists: assume client can update, weep later when
    #   the initial chef run fails. Not much we can do here -- holler at opscode.
    # * client exists, node absent: see if client can create, fail otherwise
    # * client absent, node absent: see if client can create both, fail otherwise
    # * client absent, node exists: fail (we can't get permissions)
    def sync_chef_node
      step("  syncing chef node using the server's key")
      # force-fetch the node so that we have its full attributes (the discovery
      # does not pull all of it back)
      @chef_node = handle_chef_response('404'){ Chef::Node.load( fullname ) }
      # sets @chef_client if it exists
      chef_client
      #
      case
      when    @chef_client  &&    @chef_node  then _update_chef_node # this will fail later if the chef client is in a bad state but whaddayagonnado
      when    @chef_client  && (! @chef_node) then _create_chef_node
      when (! @chef_client) && (! @chef_node) then # create both
        ensure_chef_client
        _create_chef_node
      when (! @chef_client) &&    @chef_node
        raise("The #{fullname} node exists, but its client does not.\nDue to limitations in the Opscode API, if we create a client, it will lack write permissions to the node. Small sadness now avoids much sadness later\nYou must either create a client manually, fix its permissions in the Chef console, and drop its client key where we can find it; or (if you are aware of the consequences) do \nknife node delete #{fullname}")
      end
      @chef_node
    end

    def client_key
      @client_key ||= ClusterChef::ChefClientKey.new("client-#{fullname}", chef_client) do |body|
        chef_client.private_key(body) if chef_client.present? && body.present?
        cloud.user_data(:client_key => body)
      end
    end

    def chef_client_script_content
      return @chef_client_script_content if @chef_client_script_content
      return unless cloud.chef_client_script
      script_filename = File.expand_path(cloud.chef_client_script, File.join(Chef::Config[:cluster_chef_path], 'config'))
      @chef_client_script_content = safely{ File.read(script_filename) }
    end

  protected

    # Create the chef client on the server. Do not call this directly -- go
    # through sync_chef_node.
    #
    # this is done as the eponymous client, ensuring that the client does in
    # fact have permissions on the node
    #
    # preconditions: @chef_node is set
    def _create_chef_node(&block)
      step("  creating chef node", :green)
      @chef_node = Chef::Node.new
      @chef_node.name(fullname)
      set_chef_node_attributes
      set_chef_node_environment
      sync_volume_attributes
      unless_dry_run do
        chef_api_server_as_client.post_rest('nodes', @chef_node)
      end
    end

    # Update the chef client on the server. Do not call this directly -- go
    # through create_or_update_chef_node.
    #
    # this is done as the eponymous client, ensuring that the client does in
    # fact have permissions on the node.
    #
    # preconditions: @chef_node is set
    def _update_chef_node
      step("  updating chef node", :blue)
      set_chef_node_attributes
      set_chef_node_environment
      sync_volume_attributes
      unless_dry_run do
        chef_api_server_as_admin.put_rest("nodes/#{@chef_node.name}", @chef_node)
      end
    end


    def sync_volume_attributes
      composite_volumes.each do |vol_name, vol|
        chef_node.normal[:volumes] ||= Mash.new
        chef_node.normal[:volumes][vol_name] = vol.to_mash.compact
      end
    end

    def set_chef_node_attributes
      step("  setting node runlist and essential attributes")
      @chef_node.run_list = Chef::RunList.new(*@settings[:run_list])
      @chef_node.override[:cluster_name] = cluster_name
      @chef_node.override[:facet_name]   = facet_name
      @chef_node.override[:facet_index]  = facet_index
    end

    def set_chef_node_environment
      @chef_node.chef_environment(environment.to_s)
    end

    #
    # Don't call this directly -- only through ensure_chef_node_and_client
    #
    def ensure_chef_client
      step("  ensuring chef client exists")
      return @chef_client if chef_client
      step( "    creating chef client", :green)
      @chef_client = Chef::ApiClient.new
      @chef_client.name(fullname)
      @chef_client.admin(false)
      #
      # ApiClient#create sends extra params that fail -- we'll do it ourselves
      # purposefully *not* catching the 'but it already exists' error: if it
      # didn't show up in the discovery process, we're in an inconsistent state
      unless_dry_run do
        response = chef_api_server_as_admin.post_rest("clients", { 'name' => fullname, 'admin' => false, 'private_key' => true })
        client_key.body = response['private_key']
      end
      client_key.save
      @chef_client
    end

    def chef_api_server_as_client
      return @chef_api_server_as_client if @chef_api_server_as_client
      unless File.exists?(client_key.filename)
        raise("Cannot create chef node #{fullname} -- client #{@chef_client} exists but no client key found in #{client_key.filename}.")
      end
      @chef_api_server_as_client = Chef::REST.new(Chef::Config[:chef_server_url], fullname, client_key.filename)
    end

    def chef_api_server_as_admin
      @chef_api_server_as_admin ||= Chef::REST.new(Chef::Config[:chef_server_url])
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
        return false
      end
    end

    #
    # The below *was* present but was pulled from the API by opscode for some reason (2011/10/20)
    #

    # # The client is required to have these permissions on its eponymous node
    # REQUIRED_PERMISSIONS = %w[read create update]
    #
    # #
    # # Verify that the client has required _acl's on the node.
    # #
    # # We don't raise an error, just a very noisy warning.
    # #
    # def check_node_permissions
    #   step("  ensuring chef node permissions are correct")
    #   chef_server_rest = Chef::REST.new(Chef::Config[:chef_server_url])
    #   handle_chef_response('404') do
    #     perms = chef_server_rest.get_rest("nodes/#{fullname}/_acl")
    #     perms_valid = {}
    #     REQUIRED_PERMISSIONS.each{|perm| perms_valid[perm] = perms[perm] && perms[perm]['actors'].include?(fullname) }
    #     Chef::Log.debug("Checking permissions: #{perms_valid.inspect} -- #{ perms_valid.values.all? ? 'correct' : 'BADNESS' }")
    #     unless perms_valid.values.all?
    #       ui.info(" ************************ ")
    #       ui.info(" ")
    #       ui.info(" INCONSISTENT PERMISSIONS for node #{fullname}:")
    #       ui.info("   The client[#{fullname}] should have permissions for #{REQUIRED_PERMISSIONS.join(', ')}")
    #       ui.info("   Instead, they are #{perms_valid.inspect}")
    #       ui.info("   You should create the node #{fullname} as client[#{fullname}], not as yourself.")
    #       ui.info(" ")
    #       ui.info("   Please adjust the permissions on the Opscode console, at")
    #       ui.info("     https://manage.opscode.com/nodes/#{fullname}/_acl")
    #       ui.info(" ")
    #       ui.info(" ************************ ")
    #     end
    #   end
    # end
  end
end
