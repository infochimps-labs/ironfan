module Ironfan

  module CookbookRequirements
    extend Gorillib::Concern

    def join_req(req1, req2)
      # order requirements by operation: =, >=, ~>
      req1, req2       = (req1.constraint < req2.constraint) ? [req1, req2] : [req2, req1]
      cn1, cn2         = [req1.constraint, req2.constraint]
      vers1, vers2     = [cn1.split.last, cn2.split.last]
      vers1_c, vers2_c = [vers1.split('.'), vers2.split('.')]
      op1, op2         = [req1, req2].map{ |x| x.constraint.split.first }

      if    op1 == '='  && op2 == '='
        join_eq_eq(req1, req2)
      elsif op1 == '>=' && op2 == '>='
        join_geq_geq(req1, req2)
      elsif op1 == '~>' && op2 == '~>'
        join_agt_agt(req1, req2)
      elsif op1 == '='  && op2 == '>='
        join_eq_gte(req1, req2)
      elsif op1 == '='  && op2 == '~>'
        join_eq_agt(req1, req2)
      elsif op1 == '>=' && op2 == '~>'
        join_gte_agt(req1, req2)
      end
    end

    def cookbook_req(name, constraint)
      (@cookbook_reqs ||= []) << self.class.new_req(name, constraint)
    end

    def children
      []
    end

    def cookbook_reqs
      Hash[_cookbook_reqs.map{ |x| [x.name, x.constraint] }]
    end

    def _cookbook_reqs
      [
       *shallow_cookbook_reqs,
       *child_cookbook_reqs
      ].group_by(&:name).values.map do |group|
        group.inject{ |result, req| join_req(result, req) }
      end
    end

    private

    #-----------------------------------------------------------------------------------------------

    def join_eq_eq(req1, req2)
      (vers(req1) == vers(req2)) ? req1 : bad_reqs(req1, req2)
    end

    def join_geq_geq(req1, req2)
      (vers(req1) >= vers(req2)) ? req1 : req2
    end

    def join_agt_agt(req1, req2)
      if vers_a(req1).size == vers_a(req2).size &&
          vers_a_head(req1).zip(vers_a_head(req2)).all?{|v1,v2| v1 == v2}
        (req1.constraint > req2.constraint) ? req1 : req2
      else
        bad_reqs(req1, req2)
      end
    end

    def join_eq_gte(req1, req2)
      vers(req1) >= vers(req2) ? req1 : bad_reqs(req1, req2)
    end

    def join_eq_agt(req1, req2)
      if match_v_head(req1, req2) &&
          vers_a(req1)[vers_a(req2).size - 1] >= vers_a(req2).last
        req1
      else
        bad_reqs(req1, req2)
      end
    end

    def join_gte_agt(req1, req2)
      if match_v_head(req1, req2) && vers(req1) <= vers(req2)
        req2
      else
        bad_reqs(req1, req2)
      end
    end

    def match_v_head(req1, req2)
      vers_a_head(req1, vers_a(req2).size).zip(vers_a_head(req2)).all?{|v1,v2| v1 == v2}      
    end

    def op req
      req.constraint.split.first
    end

    def vers req
      req.constraint.split.last
    end

    def vers_a req
      vers(req).split('.')
    end

    def vers_a_head(req, last = 0)
      vers_a(req)[0...last - 1]
    end

    #-----------------------------------------------------------------------------------------------

    def bad_reqs(req1, req2)
      raise ArgumentError.new("#{req1.name}: cannot reconcile #{req1.constraint} with #{req2.constraint}")
    end

    def child_cookbook_reqs
      children.map(&:_cookbook_reqs).flatten(1)
    end
    
    def shallow_cookbook_reqs
      @cookbook_reqs || self.class.default_cookbook_reqs
    end

    module ClassMethods

      def require_strict_versioning?
        @require_strict = true if @require_strict.nil?
        @require_strict
      end

      def require_strict_versioning choice
        @require_strict = choice
      end

      def new_req(name, constraint)
        if constraint.start_with?('>=') && require_strict_versioning?
          raise StandardError.new("Please don't use >= constraints. They're too vague!")
        else
          Ironfan::Plugin::CookbookRequirement.new(name: name, constraint: constraint)
        end
      end
      
      def default_cookbook_reqs
        @default_cookbook_reqs ||= []
      end
      
      def cookbook_req(name, constraint)
        default_cookbook_reqs << new_req(name, constraint)
      end

    end
  end
end
