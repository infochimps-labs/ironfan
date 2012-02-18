require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require IRONFAN_DIR("lib/ironfan")

describe Ironfan::ServerSlice do
  before do
    @slice = Ironfan.slice('webserver_demo')
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
