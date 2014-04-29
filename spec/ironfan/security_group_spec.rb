require 'spec_helper'

describe Ironfan::Dsl::SecurityGroup do
  context 'with security groups' do
    let (:auth_a) { Ironfan::Dsl::SecurityGroup.new{ authorized_by_group('a') } }
    let (:auth_b) { Ironfan::Dsl::SecurityGroup.new{ authorized_by_group('b') } }

    it 'should correctly merge them' do
      auth_a.receive!(auth_b)
      auth_a.group_authorized_by.sort.should == %w[ a b ]
    end
  end
end
