class RHash < Hash
  def self.new *args
    super(*args){|h,k| h[k] = RHash.new }
  end
end
