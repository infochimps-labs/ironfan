module ClusterChef
  #
  # A server group is a set of actual or implied servers.
  #
  # The idea is we want to be able to smoothly roll up settings
  #
  #
  class ServerSlice < ClusterChef::DslObject
    attr_reader :servers, :cluster
    include Enumerable

    def initialize cluster, servers
      super()
      @cluster = cluster
      @servers = servers
    end

    def each &block
      @servers.each(&block)
    end
    def length
      @servers.length
    end
    def empty?
      length == 0
    end

    def to_s
      str = super
      str[0..-2] + " #{@servers.map(&:fullname)}>"
    end
    
    # Return the collection of servers that are not yet 'created'
    def uncreated_servers
      ServerSlice.new cluster, servers.select{|svr| not svr.created? }
    end

    def bogus_servers
      ServerSlice.new cluster, servers.select(&:bogus?)
    end

    def sshable_servers
      ServerSlice.new cluster, servers.select(&:chef_node)
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
      servers.each{|svr| sg.merge!(svr.security_groups) }
      sg
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

    def delete_chef( delete_clients = true, delete_nodes = true)
      servers.each do |svr|
        next unless svr.chef_node
        node = svr.chef_node
        node.destroy
        svr.chef_node = nil
      end
    end

    #
    # Display!
    #

    DEFAULT_HEADINGS = ["Name", "Chef?", "InstanceID", "State", "Public IP", "Private IP", "Created At"].freeze

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
        when :detailed then DEFAULT_HEADINGS + ['Flavor', 'Image', 'AZ', 'SSH Key']
        else hh end
      headings += ["Bogus"] if servers.any?(&:bogus?)
      # probably not necessary any more
      # servers = servers.sort{ |a,b| (a.facet_name <=> b.facet_name) *9 + (a.facet_index.to_i <=> b.facet_index.to_i)*3 + (a.facet_index <=> b.facet_index) }
      defined_data = servers.map do |svr|
        hsh = {
          "Name"   => svr.fullname,
          "Facet"  => svr.facet_name,
          "Index"  => svr.facet_index,
          "Chef?"  => (svr.chef_node ? "yes" : "[red]no[reset]"),
          "Bogus"  => (svr.bogus? ? "[red]#{svr.bogosity}[reset]" : '')
        }
        if (fs = svr.fog_server)
          hsh.merge!(
              "InstanceID" => (fs.id && fs.id.length > 0) ? fs.id : "???",
              "Flavor"     => fs.flavor_id,
              "Image"      => fs.image_id,
              "AZ"         => fs.availability_zone,
              "SSH Key"    => fs.key_name,
              "State"      => "[#{fs.state == 'running' ? 'green' : 'blue'}]#{fs.state}[reset]",
              "Public IP"  => fs.public_ip_address,
              "Private IP" => fs.private_ip_address,
              "Created At" => fs.created_at.strftime("%Y%m%d-%H%M%S")
            )
        else
          hsh["State"] = "not running"
        end
        hsh.merge!(yield(svr)) if block_given?
        hsh
      end
      if defined_data.empty?
        puts "Nothing to report"
      else
        Formatador.display_compact_table(defined_data, headings)
      end
    end

  protected

    # Helper methods for iterating through the servers to do things

    def delegate_to_servers method, threaded = false
      if threaded
        # Execute across all servers in parallel
        threads = servers.map{|svr| Thread.new(svr) { |s| s.send(method) } }
        # Wait for the threads to finish and return the array of results
        threads.map{|t| t.join.value }
      else
        # Call the method for each server sequentially
        # and return the results in an array
        servers.map{|svr| svr.send(method) }
      end
    end

    def delegate_to_fog_servers method
      fog_servers.map do |fs|
        fs.send(method)
      end
    end
    
  end
end
