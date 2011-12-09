require File.expand_path('cluster_chef.rb', File.dirname(__FILE__))

module ClusterChef
  #
  #
  #
  #
  #
  class Component
    include ClusterChef::AttrStruct
    include ClusterChef::NodeUtils
    attr_reader(:node)
    dsl_attr(:sys,       :kind_of => Symbol, :coerce => :to_sym)
    dsl_attr(:subsys,    :kind_of => Symbol, :coerce => :to_sym)
    dsl_attr(:name,      :kind_of => String, :coerce => :to_s)
    dsl_attr(:realm,     :kind_of => Symbol, :coerce => :to_sym)
    dsl_attr(:timestamp, :kind_of => String, :regex => /\d{10}/)

    def initialize(node, sys, subsys, hsh={})
      @node = node
      super(sys, subsys)
      self.name      subsys.to_s.empty? ? sys.to_sym : "#{sys}_#{subsys}".to_sym
      self.timestamp ClusterChef::NodeUtils.timestamp
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
      "#{realm}-#{sys}-#{subsys}".to_s
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

    #
    # Aspects
    #

    # Harvest all aspects findable in the given node metadata hash
    #
    # @example
    #   component.harvest_all(run_context)
    #   component.dashboard(:webui)      # #<DashboardAspect name='webui' url="http://10.x.x.x:4040/">
    #   component.port(:webui_dash_port) # #<PortAspect port=4040 addr="10.x.x.x">
    #
    def harvest_all(run_context)
      self.class.aspect_types.each do |aspect_name, aspect_klass|
        res = aspect_klass.harvest(run_context, self)
        self.send(aspect_name, res)
      end
    end

    # list of known aspects
    def self.aspect_types
      @aspect_types ||= Mash.new
    end

    # add this class to the list of registered aspects
    def self.has_aspect(klass)
      self.aspect_types[klass.plural_handle] = klass
      dsl_attr(klass.plural_handle, :kind_of => Mash, :dup_default => Mash.new)
      define_method(klass.handle) do |name, val=nil, &block|
        hsh = self.send(klass.plural_handle)
        #
        hsh[name] = val if val
        # instance eval if block given (auto-vivify if necessary
        if block
          hsh[name] ||= klass.new(self, name)
          hsh[name].instance_eval(&block)
        end
        #
        hsh[name]
      end
    end

    #
    # Serialize in/out of Node
    #

    # Combines the hash for a system with the hash for its given subsys.
    # This lets us ask about the +:user+ for the 'redis.server' component,
    # whether it's set in +node[:redis][:server][:user]+ or
    # +node[:redis][:user]+. If an attribute exists on both the parent and
    # subsys hash, the subsys hash's value wins (see +:user+ in the
    # example below).
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
      if     node[sys][subsys]
        hsh.merge!(node[sys][subsys])
      elsif (subsys.to_s != '') && (not node[sys].has_key?(subsys))
        Chef::Log.warn("no subsystem data in component '#{name}', node '#{node}'")
      end
      hsh
    end

    def node_attr(attr, required=nil)
      if required && (not node_info.has_key?(attr))
        Chef::Log.warn "No definition for #{attr} in #{name} - set node[:#{sys}][:#{subsys}][#{attr.inspect}] or node[:#{sys}][#{attr.inspect}]\n#{caller[0..4].join("\n    ")}"
      end
      node_info[attr]
    end

  end
end
