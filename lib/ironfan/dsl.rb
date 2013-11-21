module Ironfan

  class Dsl < Builder
    include Gorillib::Resolution

    def join_req req1, req2
      # order requirements by operation: =, >=, ~>
      req1, req2 = (req1.constraint < req2.constraint) ? [req1, req2] : [req2, req1]
      cn1, cn2 = [req1.constraint, req2.constraint]
      vers1, vers2 = [cn1.split.last, cn2.split.last]
      vers1_c, vers2_c = [vers1.split('.'), vers2.split('.')]
      op1, op2 = [req1, req2].map{|x| x.constraint.split.first}

      if op1 == '=' and op2 == '='
        (vers1 == vers2) ? req1 : bad_reqs(req1, req2)
      elsif op1 == '>=' and op2 == '>='
        (vers1 >= vers2) ? req1 : req2
      elsif op1 == '~>' and op2 == '~>'
        if vers1_c.size == vers2_c.size and vers1_c[0...-1].zip(vers2_c[0...-1]).all?{|v1,v2| v1 == v2}
          (cn1 > cn2) ? req1 : req2
        else
          bad_reqs(req1, req2)
        end
      elsif op1 == '=' and op2 == '>='
        vers1 >= vers2 ? req1 : bad_reqs(req1, req2)
      elsif op1 == '=' and op2 == '~>'
        if vers1_c[0...(vers2_c.size - 1)].zip(vers2_c[0...-1]).all?{|v1,v2| v1 == v2} and
            vers1_c[vers2_c.size - 1] >= vers2_c.last
          req1
        else
          bad_reqs(req1, req2)
        end
      elsif op1 == '>=' and op2 == '~>'
        if vers1_c[0...(vers2_c.size - 1)].zip(vers2_c[0...-1]).all?{|v1,v2| v1 == v2} and
            vers1 <= vers2
          req2
        else
          raise ArgumentError.new("#{req1.name}: no way to satisfy #{req1.constraint} and #{req2.constraint} with a single constraint")
        end
      end
    end

    def cookbook_reqs
      Hash[_cookbook_reqs.map{|x| [x.name, x.constraint]}]
    end

    def _cookbook_reqs
      ((self.class.cookbook_reqs                               if self.class.respond_to?(:cookbook_reqs)).to_a +
       (self.children.map(&:_cookbook_reqs).flatten(1).compact if self.respond_to?(:children)).to_a).
        group_by(&:name).map(&:last).map{|x| x.inject{|acc,nxt| join_req(acc,nxt)}}
    end

    private

    def bad_reqs req1, req2
      raise ArgumentError.new("#{req1.name}: #{req1.constraint} contradicts #{req2.constraint}")
    end
  end
end
