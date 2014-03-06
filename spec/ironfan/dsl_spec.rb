require 'spec_helper'

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
        require_strict_versioning false

        cookbook_req 'a', '>= 1.2.3'
        def project(*_) end
      end
      Ironfan::Dsl::Component.template(%w[bar]) do
        require_strict_versioning false

        cookbook_req 'a', '>= 1.2.5'
        def project(*_) end
      end
      Ironfan::Dsl::Component.template(%w[baz]) do
        require_strict_versioning false

        cookbook_req 'a', '>= 1.2.7'
        def project(*_) end
      end
      Ironfan.realm(:test) do
        cluster(:just_foo) do
          foo
        end
        cluster(:foo_bar) do
          foo; bar
        end
        cluster(:nest_foo_bar) do
          foo
          facet(:bar) do
            bar
          end
        end
        cluster(:baz) do
          baz          
        end
      end
    end

    after(:each) do
      [:Foo, :Bar, :Baz].each{|x| Ironfan::Dsl::Component.send(:remove_const, x)}
    end

    it 'correctly merges version requirements in simple cases' do
      Ironfan.realm(:test).tap do |realm|
        realm.cluster(:just_foo).cookbook_reqs['a'].should == '>= 1.2.3'
        realm.cluster( :foo_bar).cookbook_reqs['a'].should == '>= 1.2.5'
      end
    end

    it 'correctly handles nested versions requirements' do
      Ironfan.realm(:test).tap do |realm|
        realm.cluster(:nest_foo_bar).tap do |cluster|
          cluster            .cookbook_reqs['a'].should == '>= 1.2.5'
          cluster.facet(:bar).cookbook_reqs['a'].should == '>= 1.2.5'
        end
        realm.cookbook_reqs['a'].should == '>= 1.2.7'
      end
    end
  end
end
