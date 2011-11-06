module ClusterChef
  #
  # A server group is a set of actual or implied servers.
  #
  # The idea is we want to be able to smoothly roll up settings
  #
  #
  class ServerSlice < ClusterChef::DslObject
    attr_reader :name, :servers, :cluster

    def initialize cluster, servers
      super()
      @name    = "#{cluster.name} slice"
      @cluster = cluster
      @servers = servers
    end

    #
    # Enumerable
    #
    include Enumerable
    def each(&block)
      @servers.each(&block)
    end
    def length
      @servers.length
    end
    def empty?
      length == 0
    end
    [:select, :find_all, :reject, :detect, :find, :drop_while].each do |method|
      define_method(method) do |*args, &block|
        ServerSlice.new cluster, @servers.send(method, *args, &block)
      end
    end

    # Return the collection of servers that are not yet 'created'
    def uncreated_servers
      select{|svr| not svr.created? }
    end

    def bogus_servers
      select(&:bogus?)
    end

    #
    # Info!
    #

    def chef_nodes
      servers.map(&:chef_node).compact
    end

    def fog_servers
      servers.map(&:fog_server).compact
    end

    def security_groups
      sg = {}
      servers.each{|svr| sg.merge!(svr.cloud.security_groups) }
      sg
    end

    def facets
      servers.map(&:facet)
    end

    def chef_roles
      [ cluster.chef_roles, facets.map(&:chef_roles) ].flatten.compact.uniq
    end

    # hack -- take the ssh_identity_file from the first server.
    def ssh_identity_file
      return if servers.empty?
      servers.first.cloud.ssh_identity_file
    end

    #
    # Actions!
    #

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

    def create_servers
      delegate_to_servers( :create_server )
    end

    def delete_chef
      delegate_to_servers( :delete_chef, true )
    end

    def sync_roles
      step("  syncing cluster and facet roles")
      chef_roles.each(&:save)
    end

    def sync_to_cloud
      sync_keypairs
      delegate_to_servers( :sync_to_cloud )
    end

    def sync_to_chef
      sync_roles
      delegate_to_servers( :sync_to_chef )
    end

    #
    # Display!
    #

    # FIXME: this is a jumble. we need to pass it in some other way.

    DEFAULT_HEADINGS = ["Name", "Chef?", "State", "InstanceID", "Public IP", "Private IP", "Created At"].to_set.freeze
    DETAILED_HEADINGS = (DEFAULT_HEADINGS + ['Flavor', 'AZ']).freeze
    EXPANDED_HEADINGS = DETAILED_HEADINGS + ['Image', 'Volumes', 'Elastic IP', 'SSH Key']

    MACHINE_STATE_COLORS  = {
      'running'       => :green,
      'pending'       => :yellow,
      'stopping'      => :magenta,
      'shutting-down' => :magenta,
      'stopped'       => :cyan,
      'terminated'    => :blue,
      'not running'   => :blue,
    }

    #
    # This is a generic display routine for cluster-like sets of nodes. If you
    # call it with no args, you get the basic table that knife cluster show
    # draws.  If you give it an array of strings, you can override the order and
    # headings displayed. If you also give it a block you can add your own logic
    # for generating content. The block is given a ClusterChef::Server instance
    # for each item in the collection and should return a hash of Name,Value
    # pairs to merge into the default fields.
    #
    def display hh = :default
      headings =
        case hh
        when :default  then DEFAULT_HEADINGS
        when :detailed then DETAILED_HEADINGS
        when :expanded then EXPANDED_HEADINGS
        else hh.to_set end
      headings += ["Bogus"] if servers.any?(&:bogus?)
      # probably not necessary any more
      # servers = servers.sort{ |a,b| (a.facet_name <=> b.facet_name) *9 + (a.facet_index.to_i <=> b.facet_index.to_i)*3 + (a.facet_index <=> b.facet_index) }
      defined_data = servers.map do |svr|
        hsh = {
          "Name"   => svr.fullname,
          "Facet"  => svr.facet_name,
          "Index"  => svr.facet_index,
          "Chef?"  => (svr.chef_node? ? "yes" : "[red]no[reset]"),
          "Bogus"  => (svr.bogus? ? "[red]#{svr.bogosity}[reset]" : '')
        }
        if (fs = svr.fog_server)
          hsh.merge!(
              "InstanceID" => (fs.id && fs.id.length > 0) ? fs.id : "???",
              "Flavor"     => fs.flavor_id,
              "Image"      => fs.image_id,
              "AZ"         => fs.availability_zone,
              "SSH Key"    => fs.key_name,
              "State"      => "[#{MACHINE_STATE_COLORS[fs.state] || 'white'}]#{fs.state}[reset]",
              "Public IP"  => fs.public_ip_address,
              "Private IP" => fs.private_ip_address,
              "Created At" => fs.created_at.strftime("%Y%m%d-%H%M%S")
            )
        else
          hsh["State"] = "not running"
        end
        hsh['Volumes'] = []
        svr.composite_volumes.each do |name, vol|
          if    vol.ephemeral_device? then next
          elsif vol.volume_id         then hsh['Volumes'] << vol.volume_id
          elsif vol.create_at_launch? then hsh['Volumes'] << vol.snapshot_id
          end
        end
        hsh['Volumes']    = hsh['Volumes'].join(',')
        hsh['Elastic IP'] = svr.cloud.public_ip if svr.cloud.public_ip
        if block_given?
          extra_info = yield(svr)
          hsh.merge!(extra_info)
          headings += extra_info.keys
        end
        hsh
      end
      if defined_data.empty?
        ui.info "Nothing to report"
      else
        Formatador.display_compact_table(defined_data, headings.to_a)
      end
    end

    def to_s
      str = super
      str[0..-2] + " #{@servers.map(&:fullname)}>"
    end

    def joined_names
      map(&:name).join(", ").gsub(/, ([^,]*)$/, ' and \1')
    end

    # Calls block on each server in parallel, each in its own thread
    #
    # @example
    #   target = ClusterChef::Cluster.slice('web_server')
    #   target.parallelize{|svr| svr.launch }
    #
    # @yield each server, in turn
    #
    # @return array (in same order as servers) of each block's result
    def parallelize
      servers.map do |svr|
        sleep(0.1) # avoid hammering with simultaneous requests
        Thread.new(svr){|svr| yield(svr) }
      end
    end

  protected

    # Helper methods for iterating through the servers to do things
    #
    # @param [Symbol]  method   -- method to call on each server
    # @param [Boolean] threaded -- execute each call in own thread
    #
    # @return array (in same order as servers) of results for that method
    def delegate_to_servers method, threaded = true
      if threaded  # Call in threads
        threads = parallelize{|svr| svr.send(method) }
        threads.map{|t| t.join.value } # Wait, returning array of results
      else         # Call the method for each server sequentially
        servers.map{|svr| svr.send(method) }
      end
    end

    def delegate_to_fog_servers method
      fog_servers.compact.map do |fs|
        fs.send(method)
      end
    end

  end
end
