module Ironfan

  class Builder
    include Gorillib::Builder

    def self.ui() Ironfan.ui ; end
    def ui()      Ironfan.ui ; end
  end

end
