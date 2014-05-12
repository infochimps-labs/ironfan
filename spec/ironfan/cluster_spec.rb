require 'spec_helper'

describe Ironfan::Dsl::Cluster do
  subject do
    Ironfan.cluster 'foo' do
      environment :dev

      role :generic

      role :is_last, :last
      role :is_first, :first
    end
    Ironfan.cluster('foo').resolve
  end

  its(:environment) { should eql :dev }

  its(:run_list) { should eql [
    "role[is_first]",
    "role[generic]",
    "role[is_last]"
    ]
  }

  context 'when merging security groups' do
    let (:secg) do
      Ironfan.cluster :merge_sec_group do
        security_group('s_cli').authorized_by_group('s_serv_cluster')
        facet(:f) do
          security_group('s_cli').authorized_by_group('s_serv_facet')
        end
      end
    end

    it 'merges all of its security groups appropriately' do
      secg.
        facet(:f).
        security_group('s_cli').
        group_authorized_by.sort.should == %w[ s_serv_cluster s_serv_facet ]
    end
  end

  context 'when merging security groups' do
    let (:cloud_secg) do
      Ironfan::Dsl::Cluster.new(:merge_sec_group) do
        cloud(:ec2).security_group('s_cli').authorized_by_group('s_serv_cluster')
        facet(:f) do
          cloud(:ec2).security_group('s_cli').authorized_by_group('s_serv_facet')
        end
      end.tap(&:resolve!)
    end

    it 'merges all of its cloud security groups appropriately' do
      pending('fixes to apparent design flaw in Ironfan/Gorillib resolution')
      cloud_secg.
        facet(:f).
        cloud(:ec2).
        security_group('s_cli').
        group_authorized_by.sort.should == %w[ s_serv_cluster s_serv_facet ]
    end
  end

  context 'with security groups' do
    let (:auth_a) { Ironfan::Dsl::SecurityGroup.new{ authorized_by_group('a') } }
    let (:auth_b) { Ironfan::Dsl::SecurityGroup.new{ authorized_by_group('b') } }

    it 'should correctly merge them' do
      auth_a.receive!(auth_b)
      auth_a.group_authorized_by.sort.should == %w[ a b ]
    end
  end
end
