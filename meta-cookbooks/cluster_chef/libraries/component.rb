require File.expand_path('cluster_chef.rb', File.dirname(__FILE__))

module ClusterChef
  class Component < Struct.new(
      :name,
      :realm,
      :timestamp
      )
    include ClusterChef::AttrStruct
    include ClusterChef::NodeUtils

    attr_reader :sys    # system name: eg +:redis+ or +:nfs+
    attr_reader :subsys # subsystem name: eg +:server+ or +:datanode+
    attr_reader :node   # node this component belongs to

    def initialize(node, sys, subsys=nil, hsh={})
      super()
      @node     = node
      @sys      = sys
      @subsys   = subsys
      self.name = subsys ? "#{sys}_#{subsys}".to_sym : sys.to_sym
      self.timestamp = ClusterChef::NodeUtils.timestamp
      merge!(hsh)
    end

    # A segmented name for the component
    # @example
    #   ClusterChef::Component.new(rc, :redis, :server, :realm => 'krypton').fullname
    #   # => 'krypton-redis-server'
    #   ClusterChef::Component.new(rc, :nfs, nil, :realm => 'krypton').fullname
    #   # => 'krypton-nfs'
    #
    # @return [String] the component's dotted name
    def fullname
      self.class.fullname(realm, sys, subsys)
    end

    # A segmented name for the component
    def self.fullname(realm, sys, subsys=nil)
      subsys ? "#{realm}-#{sys}-#{subsys}".to_s : "#{realm}-#{sys}"
    end

    #
    # Sugar for essential node attributes
    #

    # Node's cluster name
    def cluster()     node[:cluster_name] ; end
    # Node's facet name
    def facet()       node[:facet_name] ;  end
    # Node's facet index
    def facet_index() node[:facet_index] ; end

    def public_ip
      public_ip_of(node)
    end

    def private_ip
      private_ip_of(node)
    end

    def private_hostname
      private_hostname_of(node)
    end


    # Combines the hash for a system with the hash for its given subsys.
    # This lets us ask about the +:user+ for the 'redis.server' component,
    # whether it's set in +node[:redis][:server][:user]+ or
    # +node[:redis][:user]+. If an attribute exists on both the parent and
    # subsys hash, the subsys hash's value wins (see +:user+ in the
    # example below).
    #
    # If subsys is nil, just returns the direct node hash.
    #
    # @example
    #   node.to_hash
    #   # { :hadoop => {
    #   #     :user => 'hdfs', :log_dir => '/var/log/hadoop',
    #   #     :jobtracker => { :user => 'mapred', :port => 50030 } }
    #   # }
    #   node_info(:hadoop, jobtracker)
    #   # { :user => 'mapred', :log_dir => '/var/log/hadoop', :port => 50030,
    #   #   :jobtracker => { :user => 'mapred', :port => 50030 } }
    #   node_info(:hadoop, nil)
    #   # { :user => 'hdfs', :log_dir => '/var/log/hadoop',
    #   #   :jobtracker => { :user => 'mapred', :port => 50030 } }
    #
    #
    def node_info
      unless node[sys] then Chef::Log.warn("no system data in component '#{name}', node '#{node}'") ; return Mash.new ;  end
      hsh = Mash.new(node[sys].to_hash)
      if subsys
        if node[sys][subsys]
          hsh.merge!(node[sys][subsys])
        else
          Chef::Log.warn("no subsystem data in component '#{name}', node '#{node}'")
        end
      end
      hsh
    end

    def node_attr(attr, required=nil)
      if required && (not node_info.has_key?(attr))
        Chef::Log.warn "No definition for #{attr} in #{name} - set node[:#{sys}][:#{subsys}] or node[:#{sys}]"
      end
      node_info[attr]
    end

    def self.has_aspect(aspect, klass)
      @aspect_types ||= {}
      @aspect_types[aspect] = klass
    end
  end
end
