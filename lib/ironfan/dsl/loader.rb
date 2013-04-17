module Ironfan
  class Dsl

    class Loader < Ironfan::Dsl
      @@load_rank = 0

      magic     :method,        Symbol
      magic     :args,          Array
      magic     :children,      Array

      def respond_to?(method, include_private = false)
        true
      end

      def method_missing(method, *args, &block)
        rank = @@load_rank += 1
        children << Loader.new :method => method, :args => args, &block
      end

      def cluster()
        raise unless method == :cluster
        load_dsl Ironfan::Dsl::Cluster.new(:name => args.first)
      end

    protected
      def load_dsl(target)
        children.each do |child|
          child.load_dsl(target.send(child.method,*child.args))
        end
        target
      end

    end

  end
end