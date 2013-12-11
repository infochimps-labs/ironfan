require 'spec_helper'
require 'ironfan'

describe Ironfan::Dsl do
  context 'when joining requirement pairs' do
    subject{ Ironfan::Dsl.new }

    def test_join(cn1, cn2)
      name = 'foo'
      subject.join_req(Ironfan::Plugin::CookbookRequirement.new(name: name, constraint: cn1),
                       Ironfan::Plugin::CookbookRequirement.new(name: name, constraint: cn2)).constraint
    end

    it 'joins =,= requirements when valid' do
      test_join('= 1.0.0', '= 1.0.0').should == '= 1.0.0'
    end
    it 'raises when =,= requirements not valid' do
      expect{ test_join('= 1.0.0', '= 2.0.0') }.to raise_error
    end
    it 'chooses the more restrictive constraint for >= , >= requirements' do
      test_join('>= 1.0.0', '>= 2.0.0').should == '>= 2.0.0'
      test_join('>= 2.0.0', '>= 1.0.0').should == '>= 2.0.0'
    end
    it 'chooses the more restrictive constraint for ~> , ~> requirements' do
      test_join('~> 1.0', '~> 1.2').should == '~> 1.2'
      test_join('~> 1.2', '~> 1.0').should == '~> 1.2'
    end
    it 'raises when ~> , ~> requirements not valid' do
      expect{ test_join('~> 1.0', '~> 1.0.0') }.to raise_error
      expect{ test_join('~> 1.0', '~> 2.0') }.to raise_error
      expect{ test_join('~> 2.0', '~> 1.0') }.to raise_error
    end
    it 'joins =, >= requirements when valid' do
      test_join('= 1.1.0', '>= 1.1.0').should == '= 1.1.0'
      test_join('>= 1.1.0', '= 1.1.0').should == '= 1.1.0'
    end
    it 'raises when =, >= requirements not valid' do
      expect{ test_join('= 1.0.0', '>= 1.1.0') }.to raise_error
      expect{ test_join('>= 1.1.0', '= 1.0.0') }.to raise_error
    end
    it 'joins =, ~> requirements when valid' do
      test_join('= 1.1.0', '~> 1.0').should == '= 1.1.0'
      test_join('~> 1.0', '= 1.1.0').should == '= 1.1.0'
    end
    it 'raises when =, ~> requirements not valid' do
      expect{ test_join('= 2.0.0', '~> 1.0') }.to raise_error
      expect{ test_join('~> 1.0', '= 2.0.0') }.to raise_error
    end
    it 'joins >=, ~> requirements when valid' do
      test_join('>= 1.1.0', '~> 1.1.2').should == '~> 1.1.2'
      test_join('~> 1.1.2', '>= 1.1.0').should == '~> 1.1.2'
    end
    it 'raises when >=, ~> requirements not valid' do
      expect{ test_join('>= 1.1.3', '~> 1.1.2') }.to raise_error
      expect{ test_join('~> 1.1.2', '>= 1.1.3') }.to raise_error
    end
  end

  context 'when aggregating requirements' do
    before(:each) do
      Ironfan::Dsl::Component.template(%w[foo]) do
        cookbook_req 'a', '>= 1.2.3'
        def project(*_) end
      end
      Ironfan::Dsl::Component.template(%w[bar]) do
        cookbook_req 'a', '>= 1.2.5'
        def project(*_) end
      end
      Ironfan.realm(:test) do
        cluster(:just_foo) do
          foo
        end
        cluster(:foo_bar) do
          foo; bar
        end
      end
    end

    it 'correctly merges component versions' do
      Ironfan.realm(:test).cluster(:just_foo).cookbook_reqs['a'].should == '>= 1.2.3'
      Ironfan.realm(:test).cluster(:foo_bar).cookbook_reqs['a'].should == '>= 1.2.5'
    end
  end
end
