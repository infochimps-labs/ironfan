require 'delegate'

class NilCheckDelegate < Delegator
  def initialize(obj)
    super
    @delegate_sd_obj = obj
  end

  def method_missing m, *args, &blk
    __getobj__.nil? ? nil : super(m, *args, &blk)
  end

  def __getobj__
    @delegate_sd_obj
  end

  def __setobj__(obj)
    @delegate_sd_obj = obj
  end
end
