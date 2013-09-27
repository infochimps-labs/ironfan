module Ironfan
  class Dsl

    class Facet < Ironfan::Dsl::Compute
      magic      :instances,    Integer,                :default => 1
      collection :servers,      Ironfan::Dsl::Server,   :resolver => :deep_resolve
      field      :cluster_name, String

      def initialize(attrs={},&block)
        self.cluster_names      attrs[:owner].cluster_names unless attrs[:owner].nil?
        self.realm_name         attrs[:owner].realm_name unless attrs[:owner].nil?
        self.cluster_name       = attrs[:owner].cluster_name unless attrs[:owner].nil?
        self.name               = attrs[:name] unless attrs[:name].nil?
        self.facet_role         Ironfan::Dsl::Role.new(:name => "#{full_name}-facet")
        super
        for i in 0 .. instances-1; server(i); end
      end

      def full_name()           "#{cluster_name}-#{name}";      end
    end
  end
end
