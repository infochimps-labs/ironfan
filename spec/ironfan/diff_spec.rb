require 'spec_helper'
require 'gorillib/diff'
require_relative '../spec_helper/dummy_diff_drawer.rb'

describe Gorillib::DiffFormatter do
  it 'writes the indices of displayed elements for both sides' do
    TestDrawer.diffing_objs([1], [1,2]) do |drawer|
      drawer.should_receive(:display_indices).with(1,1)
    end
  end
  it 'adds objects correctly on the right' do
    TestDrawer.diffing_objs([1], [1,2]) do |drawer|
      drawer.should_receive(:display_add).with(nil, 2)
    end
  end
  it 'adds objects correctly on the left' do
    TestDrawer.diffing_objs([1,2], [1]) do |drawer|
      drawer.should_receive(:display_add).with(2, nil)
    end
  end
  it 'lists keys only on the left correctly' do
    TestDrawer.diffing_objs({a: 1, b: 2}, {a: 1}) do |drawer|
      drawer.should_receive(:only_left_key).with(:b)
    end
  end
  it 'lists keys only on the right correctly' do
    TestDrawer.diffing_objs({a: 1}, {a: 1, b: 2}) do |drawer|
      drawer.should_receive(:only_right_key).with(:b)
    end
  end
  it 'explains when elements differ' do
    TestDrawer.diffing_objs(1, 2) do |drawer|
      drawer.should_receive(:display_noteql_atoms).with(1,2)
    end
  end
  it 'explains when elements are of different classes' do
    TestDrawer.diffing_objs([], {}) do |drawer|
      drawer.should_receive(:display_hetero).with([],{})
    end
  end

  it 'correctly diffs complex objects' do

    # These aren't incredibly descriptive, but they are nice for
    # bug-hunting.

    TestDrawer.transform_ltor(1,2)
    TestDrawer.transform_ltor([1], [1,2])
    TestDrawer.transform_ltor({a: 1}, {a: 1, b: 2})
    TestDrawer.transform_ltor([1,2], [1])
    TestDrawer.transform_ltor({a: 1, b: 2}, {a: 1})
    TestDrawer.transform_ltor({a: 1, b: 2}, {a: 1, c: 3})
    TestDrawer.transform_ltor({a: [1]}, {a: [1,2]})
    TestDrawer.transform_ltor({a: [1,2]}, {a: [1]})
    TestDrawer.transform_ltor({a: [1]}, {a: [1,2]})
    TestDrawer.transform_ltor({a: [1]}, {a: [1,2]})
    TestDrawer.transform_ltor({a: [1], b: 3, c: {a: 1}, d: []}, {a: [1,2], c: [7,8], d: {a: 2}})
  end
end
