require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require CLUSTER_CHEF_DIR("lib/cluster_chef")

describe ClusterChef::ServerSlice do

  before do
    @slice = ClusterChef.slice('demoweb')
  end

  describe 'attributes' do
    it 'security groups' do
      @slice.security_groups.keys.sort.should == [
        "default",
        "demoweb", "demoweb-awesome_website", "demoweb-dbnode", "demoweb-esnode",
        "demoweb-redis_client", "demoweb-redis_server",
        "demoweb-webnode", "nfs_client", "ssh"
      ]
    end
  end
end
