module Ironfan

  class Builder
    include Gorillib::Builder

    def self.ui() Ironfan.ui ; end
    def ui()      Ironfan.ui ; end

    #
    # Utility to handle simple delegation to multiple targets
    #
    def delegate_to(targets,call)
      method,params =   call.shift
      params =          [params] unless params.is_a? Array
      targets =         [targets] unless targets.is_a? Array
      targets.each {|target| target.send(method,*params)}
    end
    def unimplemented(call)
      raise NotImplementedError, "#{call} not implemented for #{self.class}"
    end
  end

end
