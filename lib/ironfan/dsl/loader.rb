module Ironfan
  class Dsl

    class Loader < Ironfan::Dsl
      @@load_rank = 0

      magic     :method,        Symbol
      magic     :args,          Array

      collection :loader_items, Loader, :key_method => :current_rank

      def respond_to?(method, include_private = false)
        true
      end

      def method_missing(method, *args, &block)
        rank = @@load_rank += 1
        loader_items[rank] = Loader.new :method => method, :args => args, &block
      end

      def reify()
        raise unless method == :cluster
        load_dsl Ironfan::Dsl::Cluster.new(:name => args.first)
      end

    protected
      def load_dsl(target)
        loader_items.each do |item|
          item.load_dsl(target.send(item.method,*item.args))
        end
        target
      end

      def current_rank()        @@load_rank     end
    end

  end
end