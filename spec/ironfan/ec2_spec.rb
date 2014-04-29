require 'spec_helper'

describe Ironfan::Dsl::Ec2 do
  context 'with cloud-level security groups' do
    let (:cloud_a) { Ironfan::Dsl::Ec2.new{ security_group('s').authorized_by_group('a') } }
    let (:cloud_b) { Ironfan::Dsl::Ec2.new{ security_group('s').authorized_by_group('b') } }

    it 'should correctly merge them' do
      pending('fixes to apparent design bugs in Ironfan/Gorillib resolution')

      cloud_a.receive! cloud_b
      cloud_a.security_group('s').group_authorized_by.sort.should == %w[ a b ]
    end
  end
end
