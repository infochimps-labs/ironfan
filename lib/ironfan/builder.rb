module Ironfan

  class Builder
    include Gorillib::Builder

    def self.ui() Ironfan.ui ; end
    def ui()      Ironfan.ui ; end

    # helper method for turning exceptions into warnings
    def safely(*args, &block) Ironfan.safely(*args, &block) ; end

    def step(desc, *style)
      ui.info("  #{"%-15s" % (name.to_s+":")}\t#{ui.color(desc.to_s, *style)}")
    end
  end

end
