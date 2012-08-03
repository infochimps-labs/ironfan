module Ironfan

  class Builder
    include Gorillib::Builder

    def self.ui() Ironfan.ui ; end
    def ui()      Ironfan.ui ; end

    #
    # Utilities 
    # 

    # simple delegation to multiple targets
    def delegate_to(targets,options={},&block)
      raise 'missing block' unless block_given?
      [targets].flatten.each {|target| target.instance_eval &block }
    end
  end

end
