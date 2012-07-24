module Ironfan

  class Builder
    include Gorillib::Builder

    def self.ui() Ironfan.ui ; end
    def ui()      Ironfan.ui ; end

    #
    # Utility to handle simple delegation to multiple targets
    #
    def delegate_to(targets,calls)
      targets = [targets] unless params.is_a? Array
      targets.each do |target|
        calls.each do |call,params|
          params = [params] unless params.is_a? Array
          target.send(call,*params)
        end
      end
    end
  end

end
