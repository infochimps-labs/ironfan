require 'gorillib/metaprogramming/concern'
require 'ironfan/dsl/compute'
require 'ironfan/plugin/base'

module Ironfan
  class Dsl
    module ComputeTemplate
      extend Gorillib::Concern

      def initialize(*args, &blk)
        super(*args, &nil)
      end

      def around &blk
        before
        instance_eval(&blk)
        after
      end

      def after(); end
      def before(); end

      module ClassMethods
        def _project compute, &blk
          compute.around &blk
        end
      end
    end
  end
end
