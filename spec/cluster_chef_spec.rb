require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'extlib/mash'
module Chef
  Chef::Config = Mash.new( :knife => Mash.new )
end

require CLUSTER_CHEF_DIR("lib/cluster_chef")

describe "cluster_chef" do
  def load_example(name)
    require(CLUSTER_CHEF_DIR('clusters', "#{name}.rb"))
  end

  def get_cluster name
    load_example(name)
    ClusterChef.cluster(name)
  end

  describe 'successfuly runs examples' do

    describe 'demohadoop cluster' do
      before :all do
        @cluster = get_cluster(:demohadoop)
      end

      it 'loads successfuly' do
        @cluster.should be_a(ClusterChef::Cluster)
        @cluster.name.should == :demohadoop
      end

      it 'cluster is right' do
        @cluster.to_hash.should == {
          :name            => :demohadoop,
          :run_list        => ["role[base_role]", "role[chef_client]", "role[ssh]", "role[big_package]"],
          :chef_attributes => { :cluster_size =>2 },
          :cluster_role    => "demohadoop_cluster",
        }
      end

      it 'facets are right' do
        @cluster.facets.length.should == 2
        @cluster.facet(:master).to_hash.should == {
          :name            => :master,
          :run_list        => ["role[nfs_server]", "role[hadoop]", "role[hadoop_s3_keys]", "role[hadoop_master]", "hadoop_cluster::bootstrap_format_namenode", "role[hadoop_initial_bootstrap]"],
          :chef_attributes => {},
          :facet_role      => "demohadoop_master",
          :instances       => 1,
        }
        @cluster.facet(:worker).to_hash.should == {
          :name            => :worker,
          :run_list        => ["role[nfs_client]", "role[hadoop]", "role[hadoop_s3_keys]", "role[hadoop_worker]" ],
          :chef_attributes => {},
          :facet_role      => "demohadoop_worker",
          :instances       => 2,
        }
      end

      it 'security groups are right' do
        gg = @cluster.facet(:worker).security_groups
        gg.length.should == 1
        gg[:nfs_client].to_hash.should == {
          :name        => "nfs_client",
          :description => "cluster_chef generated group nfs_client"
        }
      end
    end
  end
end
