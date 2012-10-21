require 'chef/knife/cluster_launch'
require 'chef/knife/cluster_kill'

def launch_cluster(name, options = {}, &block)
  raise "No block given!" unless block_given?

  cluster = Ironfan.cluster(name)

  # Make sure that the cluster is clobbered before trying to launch it
  begin
    Chef::Knife::ClusterKill.new(['--yes', name]).run
  rescue Exception => e
    Chef::Log.fatal("Unable to terminate existing instance of cluster #{name}: #{e.inspect}")
  end

  # Launch the cluster and then yield to the testing block
  begin

    # In the case of a normal shutdown, destroy the cluster to save moolah
    RSpec.configure do |config|
      config.after(:all) do
        Chef::Log.info("Shutting down #{name} cluster")
        begin
          Chef::Knife::ClusterKill.new(['--yes', name]).run
        rescue Exception => failed_termination
          Chef::Log.fatal("Unable to kill cluster #{name} after test run: #{failed_termination.inspect}")
        end
      end
    end

    Chef::Log.info("Launching #{name} cluster")
    launcher = Chef::Knife::ClusterLaunch.new([name])
    launcher.run

    Chef::Log.info("Running tests against #{name} cluster")
    yield cluster, Ironfan.broker.discover!(cluster)

  rescue Exception => launchfail

    Chef::Log.warn("Exception occurred while launching cluster #{name}: #{launchfail.inspect}")

    # Failed tests should not result in wasted Chef/IAAS resources
    if ENV['IRONFAN_PRESERVE_TESTING_CORPSES']
      Chef::Log.warn("Failed to launch #{name} cluster, but NOT terminating cluster so that you have a chance to inspect it")
      Chef::Log.warn(launchfail.inspect)
    else
      begin
        Chef::Knife::ClusterKill.new([name, '--yes'])
      rescue Exception => death
        Chef::Log.fatal("Unable to kill cluster #{name} after failed test run: #{death.inspect}")
      end
    end
  end

end
