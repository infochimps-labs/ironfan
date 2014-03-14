require 'spec_helper'

ironfan_go!

describe Chef::Knife::ClusterBootstrap do
  let(:cluster) do
    Ironfan.load_cluster(:gunbai)
  end

  let(:target) do
    Ironfan.broker.discover!(cluster)
  end

  let(:computers) do
    Ironfan::Broker::Computers.receive(
      MultiJson.load(
        File.open(Pathname.path_to(:fixtures, 'gunbai_slice.json'))))
  end

  subject do
    described_class.new(slice)
  end

  context 'getting slice' do
    before do
      subject.stub(:relevant?){ true }
      subject.stub(:run_bootstrap)
      subject.config[:yes] = true
    end
    context 'full slice' do
      let(:slice){ ['samurai-gunbai'] }
      it 'fails if there are multiple environments' do
        expect{ subject.run }.to raise_error("Cannot bootstrap multiple chef environments")
      end
    end
    context 'partial slice' do
      let(:slice){ ['samurai-gunbai-hub'] }
      it 'runs' do
        subject.should_receive(:run_bootstrap).once
        subject.run
      end
    end

  end

end
