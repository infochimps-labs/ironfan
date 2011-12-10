require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require CLUSTER_CHEF_DIR("lib/cluster_chef")

describe ClusterChef::Server do
  include_context 'dummy_chef'

  ClusterChef::Server.class_eval do
    def chef_node
      Chef::Node.new
    end
  end

  ClusterChef::DryRunnable.class_eval do
    def unless_dry_run
      puts "Not doing that"
    end
  end

  before do
    ClusterChef::Server.stub!(:chef_node).and_return( "HI" )
    Chef::Config.stub!(:validation_key).and_return("I_AM_VALID")

    foo = ClusterChef::Server.new(ClusterChef::Facet.new(ClusterChef::Cluster.new('hi'),'there'),0)
    puts foo.inspect
    puts foo.chef_node
    @cluster = get_example_cluster('webserver_demo')
    @cluster.resolve!
    @facet   = @cluster.facet(:dbnode)
    @server  = @facet.server(0)
  end

  describe 'volumes' do
    describe '#composite_volumes' do
      it 'assembles cluster, facet and server volumes' do
        @server.composite_volumes.length.should == 5
        @cluster.volumes.length.should == 4
        @facet.volumes.length.should   == 1
        @server.volumes.length.should  == 1
      end

      it 'composites server attributes onto a volume defined in the facet' do
        vol = @server.composite_volumes[:data]
        vol.to_hash.should == {
          :name              => :data,
          :tags              => {},
          :snapshot_id       => "snap-d9c1edb1",
          :size              => 50,
          :keep              => true,
          :device            => "/dev/sdi",
          :mount_point       => "/data/db",
          :mount_options     => "defaults,nouuid,noatime",
          :fs_type           => "xfs",
          :availability_zone => "us-east-1d"
        }
      end

      it 'makes block_device_mapping for non-ephemeral storage' do
        vol = @server.composite_volumes[:data]
        vol.block_device_mapping.should == {
          "DeviceName"              => "/dev/sdi",
          "Ebs.SnapshotId"          => "snap-d9c1edb1",
          "Ebs.VolumeSize"          => 50,
          "Ebs.DeleteOnTermination" => "false"
        }
      end

      it 'skips block_device_mapping for non-ephemeral storage if volume id is present' do
        vol = @facet.server(1).composite_volumes[:data]
        vol.block_device_mapping.should be_nil
      end

    end
  end

  describe 'launch' do
    describe '#fog_description_for_launch' do
      it 'has right attributes' do

        hsh = @server.fog_description_for_launch
        hsh.delete(:user_data)
        hsh.should == {
          :image_id             => "ami-08f40561",
          :flavor_id            => "m1.large",
          :groups               => ["webserver_demo-redis_client", "webserver_demo-dbnode", "default", "ssh", "nfs_client", "webserver_demo"],
          :key_name             => :webserver_demo,
          :tags                 => {:cluster=>:webserver_demo, :facet=>:dbnode, :index=>0},
          :block_device_mapping => [
            {"DeviceName"=>"/dev/sdi", "Ebs.SnapshotId"=>"snap-d9c1edb1", "Ebs.VolumeSize"=>50, "Ebs.DeleteOnTermination"=>"false"},
            {"DeviceName"=>"/dev/sdb", "VirtualName"=>"ephemeral0"},
            {"DeviceName"=>"/dev/sdc", "VirtualName"=>"ephemeral1"},
            {"DeviceName"=>"/dev/sdd", "VirtualName"=>"ephemeral2"},
            {"DeviceName"=>"/dev/sde", "VirtualName"=>"ephemeral3"},
          ],
          :availability_zone    => "us-east-1d",
          :monitoring           => nil
        }
      end

      it 'has right user_data' do
        hsh = @server.fog_description_for_launch
        user_data_hsh = JSON.parse( hsh[:user_data] )
        user_data_hsh.keys.should == ["chef_server", "validation_client_name", "validation_key", "attributes"]
        user_data_hsh["attributes"].keys.sort.should == [
          "cluster_name", "facet_name", "facet_index",
          "node_name",
          "webnode_count",
        ]
      end
    end

  end
end
