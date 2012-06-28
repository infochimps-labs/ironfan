module Ironfan
  def self.deprecated call, replacement=nil
    correction = ", use #{replacement} instead" if replacement
    ui.warn "The '#{call}' statement is deprecated #{caller(2).first.inspect}#{correction}"
  end

  class DslBuilder    
    def to_hash
      Ironfan.deprecated 'to_hash', 'attributes'
      attributes
    end
    def to_mash
      Ironfan.deprecated 'to_mash', 'attributes'
      attributes
    end
    def reverse_merge!(attrs={})
      Ironfan.deprecated 'reverse_merge!', 'receive!'
      receive!(attrs)
    end
    def configure(attrs={},&block)
      Ironfan.deprecated 'configure', 'receive!'
      receive!(attrs, &block)
    end
  end

  class Cluster
    def use(*clusters)
      Ironfan.deprecated 'use', 'underlay'
      clusters.each do |c|
        other_cluster =  Ironfan.load_cluster(c)
        cluster.underlay        other_cluster
      end
      self
    end
  end

  class Server
    def chef_node_name name
      Ironfan.deprecated 'chef_node_name', 'fullname'
      fullname name
    end

    def composite_volumes
      Ironfan.deprecated 'composite_volumes', 'volumes'
      volumes
    end
  end

  class CloudDsl::Ec2
    def elastic_ip(*args, &block)
      Ironfan.deprecated 'elastic_ip', 'public_ip'
      public_ip(*args, &block)
    end
  end

  class Volume
    def defaults
      Ironfan.deprecated 'defaults'
    end
  end
end
