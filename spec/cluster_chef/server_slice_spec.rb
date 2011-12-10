require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require CLUSTER_CHEF_DIR("lib/cluster_chef")

describe ClusterChef::ServerSlice do
  before do
    @slice = ClusterChef.slice('webserver_demo')
  end

  describe 'attributes' do
    it 'security groups' do
      @slice.security_groups.keys.sort.should == [
        "default",
        "webserver_demo", "webserver_demo-awesome_website", "webserver_demo-dbnode", "webserver_demo-esnode",
        "webserver_demo-redis_client", "webserver_demo-redis_server",
        "webserver_demo-webnode", "nfs_client", "ssh"
      ]
    end
  end
end
