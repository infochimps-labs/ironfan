module Ironfan
  class Dsl

    class Facet < Ironfan::Dsl::Compute
      magic      :instances,    Integer,                :default => 1
      collection :servers,      Ironfan::Dsl::Server,   :resolver => :deep_resolve
      field      :cluster_name, String

      def initialize(attrs={},&block)
        self.cluster_name       = attrs[:owner].name unless attrs[:owner].nil?
        self.name               = attrs[:name] unless attrs[:name].nil?
        self.facet_role         Ironfan::Dsl::Role.new(:name => fullname.sub('-','_'))
        super
        for i in 0 .. instances-1; server(i); end
      end

      def fullname()            "#{cluster_name}-#{name}";      end

    end

  end
end