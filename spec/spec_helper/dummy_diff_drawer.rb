require 'gorillib/diff'

module TransformLeftToRight
  attr_reader :left

  DELETE_ME = Object.new

  def display_key_header(key)
    @left_lineage << [@left, key]
    @left = @left[key]

    @right_lineage << @right
    @right = @right[key]
  end

  def only_left_key(_)
    @left = DELETE_ME
  end

  def only_right_key(key)
    @left = @right
  end

  def display_add(this, other)
    if this.nil?
      @left.insert(@ix, other)
      @ix += 1
    else
      @left.delete_at(@ix)
    end
  end

  def display_hetero(this, other)
    @ix += 1
    @left = @right
  end

  def display_noteql_items(*args)
    @in_array = true
    super(*args)
    @in_array = false
  end

  def display_noteql_atoms(this, other)
    @ix += 1
    @left = @right
  end

  def decrease_indentation
    tmp = @left
    @left,key = @left_lineage.pop

    if tmp.equal?(DELETE_ME)
      @left.delete(key)
    else
      @left[key] = tmp
    end

    @right = @right_lineage.pop
  end

  def increase_indentation() end
  def indent() end

  def display_indices(ixl, ixr)
    @ix = ixr
  end
end

class TestDrawer
  include Gorillib::DiffDrawerMethods
  include TransformLeftToRight

  def initialize this, other
    @left_lineage = [@left = this]
    @right_lineage = [@right = other]
    @ix = 0
  end
  
  def self.diffing_objs this, other
    yield drawer = new(this, other)
    Gorillib::DiffFormatter.new(drawer: drawer).display_diff(this, other)
  end

  def self.transform_ltor this, other
    drawer = new(this, other)
    Gorillib::DiffFormatter.new(drawer: drawer).display_diff(this, other)
    drawer.left.should == other
  end
end
