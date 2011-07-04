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

    def to_s
      str = super
      str[0..-2] + " #{@servers.map(&:fullname)}>"
    end
    
    # def uncreated_servers
    #   # Return the collection of servers that are not yet 'created'
    #   ServerSlice.new cluster, servers.select{|svr| svr.fog_server.nil? }
    # end

    # These are some helper methods for iterating through the servers
    # to do things

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

    # This is a generic display routine for cluster-like sets of nodes. If you call
    # it with no args, you get the basic table that knife cluster show draws.
    # If you give it an array of strings, you can override the order and headings
    # displayed. If you also give it a block you can supply your own logic for
    # generating content. The block is given a ClusterChef::Server instance for each
    # item in the collection and should return a hash of Name,Value pairs to display
    # in the table.
    #
    # There is an example of how to call this functon with a block in
    # knife/cluster_launch.rb
    #
    def display headings = ["Name", "Chef?", "InstanceID", "State", "Public IP", "Created At"]
      # sorted_servers = servers.sort{ |a,b| (a.facet_name <=> b.facet_name) *9 + (a.facet_index.to_i <=> b.facet_index.to_i)*3 + (a.facet_index <=> b.facet_index) }
      defined_data = servers.map do |svr|
        hsh = {
          "Name"    => svr.fullname,
          "Facet"   => svr.facet.name,
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
        hsh.merge!(yield(svr)) if block_given?
        hsh
      end

      if defined_data.empty?
        puts "Nothing to report"
      else
        Formatador.display_compact_table(defined_data, headings)
      end
    end

  end
end
