require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require CLUSTER_CHEF_DIR("lib/cluster_chef")

describe "cluster_chef" do
  describe 'successfuly runs example' do

    describe 'webserver_demo:' do
      before :all do
        @cluster = get_example_cluster(:webserver_demo)
        @cluster.resolve!
      end

      it 'loads successfuly' do
        @cluster.should be_a(ClusterChef::Cluster)
        @cluster.name.should == :webserver_demo
      end

      it 'cluster is right' do
        @cluster.to_hash.should == {
          :name            => :webserver_demo,
          :run_list        => ["role[base_role]", "role[chef_client]", "role[ssh]", "role[nfs_client]", "role[big_package]", "role[webserver_demo_cluster]"],
          :chef_attributes => { :webnode_count => 6 },
          :facet_name    => "webserver_demo_cluster",
        }
      end

      it 'defaults cluster' do
        defaults_cluster = ClusterChef.cluster(:defaults)
        cloud_hash = defaults_cluster.cloud.to_hash
        [:security_groups, :user_data].each{|k| cloud_hash.delete k }
        cloud_hash.should == {
          :availability_zones => ['us-east-1d'],
          :region             => "us-east-1",
          :flavor             => "m1.small",
          :image_name         => "lucid",
          :backing            => "ebs",
          :disable_api_termination => false,
          :public_ip         => false,
          :bootstrap_distro   => "ubuntu10.04-cluster_chef",
        }
      end

      it 'cluster cloud is right' do
        cloud_hash = @cluster.cloud.to_hash
        [:security_groups, :user_data].each{|k| cloud_hash.delete k }
        cloud_hash.should == {
          :availability_zones => ['us-east-1d'],
          :region             => "us-east-1",
          :flavor             => "t1.micro",
          :image_name         => "maverick",
          :backing            => "instance",
          :disable_api_termination => false,
          :public_ip         => false,
          :bootstrap_distro   => "ubuntu10.04-cluster_chef",
          :keypair            => :webserver_demo,
        }
      end

      it 'facet cloud is right' do
        cloud_hash = @cluster.facet(:webnode).cloud.to_hash
        [:security_groups, :user_data].each{|k| cloud_hash.delete k }
        cloud_hash.should == {
          :backing            => "ebs",
        }
      end

      it 'webnode facets are right' do
        @cluster.facets.length.should == 3
        fct = @cluster.facet(:webnode)
        fct.to_hash.should == {
          :name            => :webnode,
          :run_list        => ["role[nginx]", "role[redis_client]", "role[mysql_client]", "role[elasticsearch_client]", "role[awesome_website]", "role[webserver_demo_webnode]"],
          :chef_attributes => {:split_testing=>{:group=>"A"}},
          :facet_role      => "webserver_demo_webnode",
          :instances       => 6,
        }
      end

      it 'dbnode facets are right' do
        fct = @cluster.facet(:dbnode)
        fct.to_hash.should == {
          :name            => :dbnode,
          :run_list        => ["role[mysql_server]", "role[redis_client]", "role[webserver_demo_dbnode]" ],
          :chef_attributes => {},
          :facet_role      => "webserver_demo_dbnode",
          :instances       => 2,
        }
        fct.cloud.flavor.should == 'c1.xlarge'
        fct.server(0).cloud.flavor.should == 'm1.large'
      end

      it 'esnode facets are right' do
        fct = @cluster.facet(:esnode)
        fct.to_hash.should == {
          :name            => :esnode,
          :run_list        => ["role[nginx]", "role[redis_server]", "role[elasticsearch_data_esnode]", "role[elasticsearch_http_esnode]", "role[webserver_demo_esnode]"],
          :chef_attributes => {},
          :facet_role      => "webserver_demo_esnode",
          :instances       => 1,
        }
        fct.cloud.flavor.should == 'm1.large'
      end

      it 'cluster security groups are right' do
        gg = @cluster.security_groups
        gg.keys.should == ['default', 'ssh', 'nfs_client', 'webserver_demo']
      end

      it 'facet webnode security groups are right' do
        gg = @cluster.facet(:webnode).security_groups
        gg.keys.sort.should == ["default", "webserver_demo", "webserver_demo-awesome_website", "webserver_demo-redis_client", "webserver_demo-webnode", "nfs_client", "ssh"]
        gg['webserver_demo-awesome_website'].range_authorizations.should == [[80..80, "0.0.0.0/0", "tcp"], [443..443, "0.0.0.0/0", "tcp"]]
      end

      it 'facet dbnode security groups are right' do
        gg = @cluster.facet(:dbnode).security_groups
        gg.keys.sort.should == ["default", "webserver_demo", "webserver_demo-dbnode", "webserver_demo-redis_client", "nfs_client", "ssh"]
      end

      it 'facet esnode security groups are right' do
        gg = @cluster.facet(:esnode).security_groups
        gg.keys.sort.should == ["default", "webserver_demo", "webserver_demo-esnode", "webserver_demo-redis_server", "nfs_client", "ssh"]
        gg['webserver_demo-redis_server'][:name].should == "webserver_demo-redis_server"
        gg['webserver_demo-redis_server'][:description].should == "cluster_chef generated group webserver_demo-redis_server"
        gg['webserver_demo-redis_server'].group_authorizations.should == [['webserver_demo-redis_client', nil]]
      end

      it 'has servers' do
        @cluster.servers.map(&:fullname).should == [
          "webserver_demo-dbnode-0", "webserver_demo-dbnode-1",
          "webserver_demo-esnode-0",
          "webserver_demo-webnode-0", "webserver_demo-webnode-1", "webserver_demo-webnode-2", "webserver_demo-webnode-3", "webserver_demo-webnode-4", "webserver_demo-webnode-5"
        ]
      end

      describe 'resolving servers gets right' do
        before do
          @server = @cluster.slice(:webnode, 5).first
          @server.cloud.stub!(:validation_key).and_return("I_AM_VALID")
          @server.resolve!
        end

        it 'attributes' do
          @server.to_hash.should == {
            :name            => 'webserver_demo-webnode-5',
            :run_list        => ["role[base_role]", "role[chef_client]", "role[ssh]", "role[nfs_client]", "role[big_package]", "role[webserver_demo_cluster]", "role[nginx]", "role[redis_client]", "role[mysql_client]", "role[elasticsearch_client]", "role[awesome_website]", "role[webserver_demo_webnode]"],
            :instances => 6,
            :chef_attributes => {
              :split_testing  => {:group=>"B"},
              :webnode_count  => 6,
              :node_name      => "webserver_demo-webnode-5",
              :cluster_name => :webserver_demo, :facet_name => :webnode, :facet_index => 5,
            },
          }
        end

        it 'security groups' do
          @server.security_groups.keys.sort.should == ['default', 'webserver_demo', 'webserver_demo-awesome_website', 'webserver_demo-redis_client', 'webserver_demo-webnode', 'nfs_client', 'ssh']
        end
        it 'run list' do
          @server.run_list.should == ["role[base_role]", "role[chef_client]", "role[ssh]", "role[nfs_client]", "role[big_package]", "role[webserver_demo_cluster]", "role[nginx]", "role[redis_client]", "role[mysql_client]", "role[elasticsearch_client]", "role[awesome_website]", "role[webserver_demo_webnode]"]
        end

        it 'user_data' do
          @server.cloud.user_data.should == {
            "chef_server"            => "https://api.opscode.com/organizations/infochimps",
            "validation_client_name" => "chef-validator",
            "validation_key"         => "I_AM_VALID",
          }
        end

        it 'cloud settings' do
          hsh = @server.cloud.to_hash
          hsh.delete(:security_groups)
          hsh.delete(:user_data)
          hsh.should == {
            :availability_zones => ["us-east-1c"],
            :region             => "us-east-1",
            :flavor             => "t1.micro",
            :image_name         => "maverick",
            :backing            => "ebs",
            :disable_api_termination => false,
            :public_ip         => false,
            :bootstrap_distro   => "ubuntu10.04-cluster_chef",
            :keypair            => :webserver_demo,
          }
        end

      end
    end
  end
end
