require 'spec_helper'

describe Ironfan::Dsl::MachineManifest do
  context 'it disregards whether values are strings or symbols' do
    before(:each) do
      Ironfan::Dsl::Component.template(%w[baz bif]) do
        collection :bams, Symbol
        magic :pow, Whatever
      end
    end

    def comparable_manifest(hsh)
      Ironfan::Dsl::MachineManifest.receive(components: [Ironfan::Dsl::Component::BazBif.new(hsh)]).to_comparable
    end

    it 'when those values are contained in an array of within its serialization' do
      comparable_manifest(bam: [:a, :b, :c]).should == comparable_manifest(bam: %w[a b c])
      comparable_manifest(pow: [:a, :b, :c]).should == comparable_manifest(pow: %w[a b c])
    end
    it 'when those values are contained in hash within its serialization' do
      comparable_manifest(pow: {a: 'a'}).should == comparable_manifest(pow: {'a' => :a})
    end
    it 'correctly stores the chef environment' do
      node = Chef::Node.json_create('chef_environment' => 'buzi', 'recipes' => [])
      Ironfan::Dsl::MachineManifest.from_remote(nil, nil, nil, node, nil, nil, nil, nil).environment.to_s.should == 'buzi'
    end
  end
end
