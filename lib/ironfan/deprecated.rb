module Ironfan
  class DslBuilder    
    def to_hash
      ui.warn "The 'to_hash' statement is deprecated #{caller.first.inspect}, use attributes instead"
      attributes
    end
    def configure(attrs={},&block)
      ui.warn "The 'configure' statement is deprecated #{caller.first.inspect}, use receive! instead"
      receive!(attrs, &block)
    end
  end

  class Cluster
    #
    # **DEPRECATED**: This doesn't really work -- use +reverse_merge!+ instead
    #
    def use(*clusters)
      ui.warn "The 'use' statement is deprecated #{caller.inspect}"
      clusters.each do |c|
        other_cluster =  Ironfan.load_cluster(c)
        reverse_merge! other_cluster
      end
      self
    end

  end

  class Server
    # **DEPRECATED**: Please use +fullname+ instead.
    def chef_node_name name
      ui.warn "[DEPRECATION] `chef_node_name` is deprecated.  Please use `fullname` instead."
      fullname name
    end
  end

  class CloudDsl::Ec2
    # **DEPRECATED**: Please use +public_ip+ instead.
    def elastic_ip(*args, &block)
      public_ip(*args, &block)
    end
  end

end
