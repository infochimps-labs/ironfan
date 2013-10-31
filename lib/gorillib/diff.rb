require 'diff-lcs'

module Gorillib
  module AnsiColors
    def cyan str
      "\e[36m#{str}\e[0m"
    end
  end

  module DiffDisplayTools
    def display_key_header key
      indent; @stream.puts("#{key}:")
    end

    #-------------------------------------------------------------------------------------------------

    def only_left_key key
      indent; @stream.puts("only on #{b_left}")
    end

    def only_right_key key
      indent; @stream.puts("only on #{b_right}")
    end

    #-------------------------------------------------------------------------------------------------

    def display_hetero this, other
      indent; @stream.puts("class #{this.class} is not #{other.class}")
    end

    #-------------------------------------------------------------------------------------------------

    def display_noteql_atoms this, other
      indent; @stream.puts("#{b_left}: #{this.inspect}")
      indent; @stream.puts("#{b_right}: #{other.inspect}")
    end

    #-------------------------------------------------------------------------------------------------

    def display_eql(it)
      indent; @stream.puts("#{'='} #{it}")
    end

    def display_add(itl, itr)
      indent
      if itl.nil?
        @stream.puts("#{b_left}: #{itr}")
      else
        @stream.puts("#{b_right}: #{itl}")
      end
    end

    #-------------------------------------------------------------------------------------------------

    def indent
      @stream.write(" " * @indentation)
    end

    def display_indices(ixl, ixr)
      indent; @stream.puts("#{b_left} ix: #{ixl}, #{b_right} ix: #{ixr}")
    end

    #------------------------------------------------------------------------------------------------

    def b_left
      "[#{header(@left)}]"
    end

    def b_right
      "[#{header(@right)}]"
    end

    def decrease_indentation
      @indentation -= @tab_width
    end

    def header str
      cyan(str)
    end

    def increase_indentation
      @indentation += @tab_width
    end
  end

  module DiffDrawerMethods
    def for_subhash(key)
      display_key_header(key)
      increase_indentation
      yield
      decrease_indentation
    end

    #-------------------------------------------------------------------------------------------------

    def display_diff_indices diff_subset
      return if diff_subset.nil? or diff_subset.empty?
      diff_subset.first.tap do |cchange|
        display_indices(cchange.old_position, cchange.new_position)
      end
    end

    def display_eql_items diff_subset
      return if diff_subset.nil?
      diff_subset.each do |cchange|
        display_eql(cchange.old_element)
      end
    end

    def display_noteql_items diff_subset
      return if diff_subset.nil?
      diff_subset.each do |cchange|
        display_noteql_atoms(cchange.old_element, cchange.new_element)
      end
    end

    def display_add_items diff_subset
      return if diff_subset.nil?
      diff_subset.each do |cchange|
        display_add(cchange.old_element, cchange.new_element)
      end
    end
  end

  class DiffDrawer
    include AnsiColors
    include DiffDisplayTools
    include DiffDrawerMethods

    def initialize options = {}
      @stream = options[:stream] || $stdout
      @left = options[:left] || 'left'
      @right = options[:right] || 'right'
      @indentation = options[:indentation] || 0
      @tab_width = options[:tab_width] || 4
    end
  end

  class DiffFormatter
    def initialize(options = {})
      @drawer = (options[:drawer] ||
                 DiffDrawer.new(stream: options.delete(:stream),
                                left: options.delete(:left),
                                right: options.delete(:right),
                                indentation: options.delete(:indentation),
                                tab_width: options.delete(:tab_width)))

      @context_atoms = options[:context_atoms] || 0
      @display_last_suffix = options[:display_last_suffix] || display_last_suffix_p
      @display_this_prefix = options[:display_this_prefix] || nop_p
    end

    def display_diff(this, other)
      if this.is_a?(Hash) && other.is_a?(Hash)
        display_diff_hash(this, other)
      elsif this.is_a?(Array) && other.is_a?(Array)
        display_diff_arr(this, other)
      elsif ((this.is_a?(Hash) != other.is_a?(Hash)) ||
             (this.is_a?(Array) != other.is_a?(Array)))
        display_diff_hetero(this, other)
      else
        display_diff_atom(this, other)
      end
    end

    private

    #-------------------------------------------------------------------------------------------------

    def display_diff_hash(this, other)
      (this.keys & other.keys).each do |key|
        if this[key] != other[key]
          @drawer.for_subhash(key){ display_diff(this[key], other[key]) }
        end
      end
      (this.keys - other.keys).each do |key|
        @drawer.for_subhash(key){ @drawer.only_left_key(key) }
      end
      (other.keys - this.keys).each do |key|
        @drawer.for_subhash(key){ @drawer.only_right_key(key) }
      end
    end

    def display_diff_hetero(this, other)
      @drawer.display_hetero(this, other)
    end

    def display_diff_atom(this, other)
      if this != other
        @drawer.display_noteql_atoms(this, other)
      end
    end

    def display_diff_arr(this, other)
      Diff::LCS.sdiff(this, other).chunk{|x| type_of(x)}.each do |type, diff_atoms|
        case type
        when '=' then next_step(diff_atoms, type)
        when '+' then next_step(diff_atoms, type){ @drawer.display_add_items(diff_atoms) }
        when '!' then next_step(diff_atoms, type){ @drawer.display_noteql_items(diff_atoms) }
        end
      end
    end

    #-------------------------------------------------------------------------------------------------
    
    def next_step(diff_atoms, type)
      if type == '='
        @display_this_prefix.call diff_atoms
        yield(diff_atoms) if block_given?
        @display_last_suffix = display_last_suffix_p diff_atoms
        @display_this_prefix = nop_p
      else
        @display_last_suffix.call
        yield(diff_atoms) if block_given?
        @display_last_suffix = nop_p
        @display_this_prefix = display_this_prefix_p
      end
    end

    #-------------------------------------------------------------------------------------------------

    def display_this_prefix_p()
      ->(diff_subset) do
        diff_subset = diff_subset[0...@context_atoms]
        @drawer.display_eql_items(diff_subset)
      end
    end

    def display_last_suffix_p(diff_subset = [])
      ->() do
        to_display = diff_subset[[0, (diff_subset.size - @context_atoms)].max..-1]
        if diff_subset.empty?
          @drawer.display_indices(0,0)
        elsif to_display.empty?
          @drawer.
            display_indices(diff_subset.first.old_position + diff_subset.map(&:old_element).compact.size,
                            diff_subset.first.new_position + diff_subset.map(&:new_element).compact.size)
        else
          @drawer.display_indices(to_display.first.old_position, to_display.first.new_position)
        end

        @drawer.display_eql_items(to_display)
      end
    end

    def nop_p() ->(*_) {} end

    #-------------------------------------------------------------------------------------------------

    def type_of(diff_atom)
      if diff_atom.old_element == diff_atom.new_element
        '='
      elsif diff_atom.old_element.nil? || diff_atom.new_element.nil?
        '+'
      else
        '!'
      end
    end
  end
end
