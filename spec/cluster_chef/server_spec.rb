require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require CLUSTER_CHEF_DIR("lib/cluster_chef")

describe ClusterChef::Server do
  before do
    Chef::Config.stub!(:validation_key).and_return("I_AM_VALID")
    @cluster = get_example_cluster('demoweb')
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
          :volume_id         => "vol-12345",
          :snapshot_id       => "snap-d9c1edb1",
          :size              => 50,
          :keep              => true,
          :device            => "/dev/sdi",
          :mount_point       => "/data/db",
          :mount_options     => "defaults,nouuid,noatime",
          :fs_type           => "xfs",
          :availability_zone => "us-east-1a"
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
          :groups               => ["demoweb-redis_client", "demoweb-dbnode", "default", "ssh", "nfs_client", "demoweb"],
          :key_name             => :demoweb,
          :tags                 => {:cluster=>:demoweb, :facet=>:dbnode, :index=>0},
          :block_device_mapping => [
            {"DeviceName"=>"/dev/sdi", "Ebs.SnapshotId"=>"snap-d9c1edb1", "Ebs.VolumeSize"=>50, "Ebs.DeleteOnTermination"=>"false"},
            {"DeviceName"=>"/dev/sdc", "VirtualName"=>"ephemeral0"},
            {"DeviceName"=>"/dev/sdd", "VirtualName"=>"ephemeral1"},
            {"DeviceName"=>"/dev/sde", "VirtualName"=>"ephemeral2"},
            {"DeviceName"=>"/dev/sdf", "VirtualName"=>"ephemeral3"},
          ],
          :availability_zone    => "us-east-1a",
          :monitoring           => nil
        }
      end

      it 'has right user_data' do
        hsh = @server.fog_description_for_launch
        user_data_hsh = JSON.parse( hsh[:user_data] )
        user_data_hsh.keys.should == ["chef_server", "validation_client_name", "validation_key", "attributes"]
        user_data_hsh["attributes"].keys.sort.should == [
          "cluster_chef", "cluster_name", "cluster_role", "cluster_role_index",
          "facet_index", "facet_name", "node_name",
          "run_list", "webnode_count",
        ]
      end
    end

  end
end
