module Ironfan

  class Builder
    include Gorillib::Builder

    def self.ui() Ironfan.ui ; end
    def ui()      Ironfan.ui ; end

    def delegate_to(*args,&block)
      Ironfan.delegate_to(*args,&block)
    end
  end

end
