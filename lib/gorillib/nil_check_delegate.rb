require 'delegate'

class NilCheckDelegate < Delegator
  def initialize(obj)
    super
    @delegate_sd_obj = obj
    @depth = 0
  end

  def nilcheck_depth(depth = 0)
    @depth = depth
    self
  end

  def _wrap(obj)
    ((@depth -= 1) >= 0) ? self.class.new(obj) : obj
  end

  def method_missing m, *args, &blk
    _wrap(__getobj__.nil? ? nil : super(m, *args, &blk))
  end

  def __getobj__
    @delegate_sd_obj
  end

  def __setobj__(obj)
    @delegate_sd_obj = obj
  end
end
