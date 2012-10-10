require 'spec_helper'

require 'ironfan'

describe Ironfan::Dsl::Facet do
  let :troop do
    Ironfan.cluster :troop do
      environment :dev

      role      :generic
      role      :is_last, :last
      role      :is_first, :first

      facet :happy do
        role    :generic
      end
    end
  end

  context 'dsl' do
    subject{ troop.facet(:happy) }

    its(:name)        { should eql 'happy' }
    its(:environment) { should eql :dev }

    its(:run_list) { should eql [
        "role[is_first]",
        "role[generic]",
        "role[is_last]"
      ]
    }

    it 'sets instances' do
      subject.instances.should == 1
      subject.instances(2)
      subject.instances.should == 2
    end

    it 'wtf' do
      troop.receive! do
        facet(:sneezy).cloud(:ec2).bits(32)
        facet(:sneezy).instances.should == 1
        facet :sneezy do
          self.instances.should == 1
          instances(2)
          self.instances.should == 2
        end
        facet(:sneezy).instances.should == 2
      end
      troop.facet(:sneezy).instances.should == 2
    end

    context 'run list ordering' do
      it "facet :first roles follow cluster :first roles" do
        subject.role(:even_firster, :first)
        subject.run_list.should == [ "role[is_first]", "role[even_firster]", "role[generic]", "role[is_last]" ]
      end
      it "facet :last roles follow cluster :last roles" do
        subject.role(:even_laster, :last)
        subject.run_list.should == [ "role[is_first]", "role[generic]", "role[is_last]", "role[even_laster]" ]
      end
    end
  end

end
