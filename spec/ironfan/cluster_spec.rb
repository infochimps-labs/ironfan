require 'spec_helper'

describe Ironfan::Dsl::Cluster do
  subject do
    Ironfan.cluster 'foo' do
      environment :dev

      role :generic

      role :is_last, :last
      role :is_first, :first
    end
  end

  its(:environment) { should eql :dev }

  its(:run_list) { should eql [
    "role[is_first]",
    "role[generic]",
    "role[is_last]"
    ]
  }
end
