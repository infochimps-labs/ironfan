# cluster_chef

Chef is a powerful tool for maintaining and describing the software and configurations that let a machine provide its services.

cluster_chef is

* a clean, expressive way to describe how machines and roles are assembled into a working cluster.
* Our collection of Industrial-strength, cloud-ready recipes for Hadoop, Cassandra, HBase, Elasticsearch and more.
* a set of conventions and helpers that make provisioning cloud machines easier.

## Walkthrough

Here's a very simple cluster:


```ruby
ClusterChef.cluster 'demosimple' do
  cloud(:ec2) do
    flavor              't1.micro'
  end

  role                  :base_role
  role                  :chef_client
  role                  :ssh

  # An NFS server to hold your home drives.
  facet :homebase do
    instances           1
    role                :nfs_server
    facet_role.default_attributes({
      :nfs_server => { :exports => '/home' }
      })
  end

  # A throwaway facet for development.
  facet :sandbox do
    instances           2
    cloud do
      flavor           'm1.large'
      backing          'ebs'
    end
    role                :nfs_client
  end
end
```

It defines a cluster named demosimple. A cluster is a group of servers united around a common purpose. 

The demosimple cluster has two 'facets' -- a subgroup of interchangeable servers that provide a logical set of systems.

The first facet, 'homebase', has one server, which will be named 'demosimple-homebase-0'; the 'sandbox' facet has two servers, 'demosimple-sandbox-0' and 'demosimple-sandbox-1'.

Each server inherits the appropriate behaviors from its facet and cluster. All the servers in this cluster have the 'base_role', 'chef_client' and 'ssh' roles. The homebase server additionally applies the NFS chef role, while the sandboxen add the 'nfs_client' role.

As you can see, the sandbox facet asks for a different flavor of machine ('m1.large') than the cluster default ('t1.micro'). Settings in the facet override those in the server, and settings in the server override those of its facet, so you can economically describe only what's significant about each machine.

ClusterChef speaks naturally to both Chef and your cloud provider. The `facet_role.default_attributes` statement will be synchronized to the chef server. Your chef roles should focus system-specific information; the cluster file lets you see the architecture as a whole.

With these simple settings, if you have already [set up chef's knife to launch cloud servers](http://wiki.opscode.com/display/chef/Launch+Cloud+Instances+with+Knife), typing `knife cluster launch demosimple --bootstrap` will (using Amazon EC2 as an example):

* Synchronize to the chef server:
  - create chef roles on the server for the cluster and each facet.
  - apply role directives (eg the homebase's `default_attributes` declaration).
  - create a node for each machine
  - apply the runlist to each node 
* Set up security isolation:
  - uses a keypair (login ssh key) isolated to that cluster
  - Recognizes the `ssh` role, and add a security group `ssh` that by default opens port 22.
  - Recognize the `nfs_server` role, and adds security groups `nfs_server` and `nfs_client`
  - Authorizes the `nfs_server` to accept connections from all `nfs_client`s. Machines in other clusters that you mark as `nfs_client`s can connect to the NFS server, but are not automatically granted any other access to the machines in this cluster. ClusterChef's opinionated behavior is about more than saving you effort -- tying this behavior to the chef role means you can't screw it up. 
* Launches the machines in parallel:
  - passes a JSON-encoded user_data hash specifying the machine's chef `node_name` and client key. An appropriately-configured machine image will need no further bootstrapping -- it will connect to the chef server with the appropriate identity and proceed completely unattended.
* Syncronizes to the cloud provider:
  - Applies EC2 tags to the machine, so that you 
  
  ![AWS Console screenshot](http://github.com/infochimps/cluster_chef/tree/version_3/notes/)


```ruby
ClusterChef.cluster 'demohadoop' do
  cloud :ec2 do
    image_name          "maverick"
    flavor              "c1.medium"
    availability_zones  ['us-east-1d']
    security_group :logmuncher do
      authorize_group "webnode"
    end
  end
  
  facet 'master' do
    instances           1
    role                "nfs_server"
    role                "hadoop_master"
    role                "hadoop_worker"
    role                "hadoop_initial_bootstrap"
  end

  facet :webnode do
    instances           2
    role                "nfs_client"
    role                "hadoop_worker"

    volume(:server_logs) do
      size              5                           
      keep              true                        
      device            '/dev/sdi'                  
      mount_point       '/server_logs'              
      mount_options     'defaults,nouuid,noatime'   
      fs_type           'xfs'                       
      snapshot_id       'snap-d9c1edb1'             
    end
    server(0).volume(:server_logs){ volume_id('vol-12345') }
    server(1).volume(:server_logs){ volume_id('vol-6789a') }
  end

  facet :esnode do
    instances           1
    role                "nginx"
    role                "elasticsearch_data_esnode"
    role                "elasticsearch_http_esnode"
    #
    cloud.flavor        "m1.large"
  end
  
end
```

This defines a *cluster* (group of machines that serve some common purpose) with two *facets*, or unique configurations of machines within the cluster. (For another example, a webserver farm might have a loadbalancer facet, a database facet, and a webnode facet).

In the example above, the master serves out a home directory over NFS, and runs the processes that distribute jobs to hadoop workers. In this small cluster, the master also has workers itself, and a utility role that helps initialize it out of the box.

There are 2 workers; they use the home directory served out by the master, and run the hadoop worker processes. 

Lastly, we define what machines to use for this cluster. Instead of having to look up and type in an image ID, we just say we want the Ubuntu 'Lucid' distribution on a c1.medium machine. Cluster_chef understands that this means we need the 32-bit image in the us-east-1 region, and makes the cloud instance request accordingly. It also creates a 'logmunchers' security group, opening it so all the 'webnode' machines can push their server logs onto the HDFS.

The following commands launch each machine, and once ready, ssh in to install chef and converge all its software.

```ruby
knife cluster launch demohadoop master --bootstrap
knife cluster launch demohadoop worker --bootstrap
```

You can also now launch the entire cluster at once with the following

```ruby
knife cluster launch demohadoop --bootstrap
```

The cluster launch operation is idempotent: nodes that are running won't be started!

## Philosophy

Some general principles of how we use chef.

* *Chef server is never the repository of truth* -- it only mirrors the truth.
  - a file is tangible and immediate to access
* Specifically, we want truth to live in the git repo, and be enforced by the chef server. *There is no truth but git, and chef is its messenger*.
  - this means that everything is versioned, documented and exchangeable.
* *Systems, services and significant modifications cluster should be obvious from the `clusters` file*.  I don't want to have to bounce around nine different files to find out which thing installed a redis:server.
  - basically, the existence of anything that opens a port should be obvious when I look at the cluster file.
* *Roles define systems, clusters assemble systems into a machine*.
  - For example, a resque worker queue has a redis, a webserver and some config files -- your cluster should invoke a @whatever_queue@ role, and the @whatever_queue@ role should include recipes for the component services.
  - the existence of anything that opens a port _or_ runs as a service should be obvious when I look at the roles file.
* *include_recipe considered harmful* Do NOT use include_recipe for anything that a) provides a service, b) launches a daemon or c) is interesting in any way. (so: @include_recipe java@ yes; @include_recipe iptables@ no.) You should note the dependency in the metadata.rb. This seems weird, but the breaking behavior is purposeful: it makes you explicitly state all dependencies.
* It's nice when *machines are in full control of their destiny*.
  - initial setup (elastic IP, attaching a drive) is often best enforced externally
  - but machines should be ablt independently assert things like load balancer registration that that might change at any point in the lifetime.
* It's even nicer, though, to have *full idempotency from the command line*: I can at any time push truth from the git repo to the chef server and know that it will take hold.


---------------------------------------------------------------------------

## Getting Started

This assumes you have installed chef, have a working chef server, and have an AWS account. If you can run knife and use the web browser to see your EC2 console, you can start here. If not, see the instructions below.

### Setup

```ruby
bundle install
```

#### Knife setup

In your <code>$DOT_CHEF_DIR/knife.rb</code>, modify the cookbook path (to include cluster_chef/cookbooks and cluster_chef/site-cookbooks) and to add settings for @cluster_chef_path@, @cluster_path@ and @keypair_path@. Here's mine:

```
        current_dir = File.dirname(__FILE__)
        organization  = 'CHEF_ORGANIZATION'
        username      = 'CHEF_USERNAME'

        # The full path to your cluster_chef installation
        cluster_chef_path File.expand_path("#{current_dir}/../cluster_chef")
        # The list of paths holding clusters
        cluster_path      [ File.expand_path("#{current_dir}/../clusters") ]
        # The directory holding your cloud keypairs
        keypair_path      File.expand_path(current_dir)

        log_level                :info
        log_location             STDOUT
        node_name                username
        client_key               "#{keypair_path}/#{username}.pem"
        validation_client_name   "#{organization}-validator"
        validation_key           "#{keypair_path}/#{organization}-validator.pem"
        chef_server_url          "https://api.opscode.com/organizations/#{organization}"
        cache_type               'BasicFile'
        cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )

        # The first things have lowest priority (so, site-cookbooks gets to win)
        cookbook_path            [
          "#{cluster_chef_path}/cookbooks",
          "#{current_dir}/../cookbooks",
          "#{current_dir}/../site-cookbooks",
        ]

        # If you primarily use AWS cloud services:
        knife[:ssh_address_attribute] = 'cloud.public_hostname'
        knife[:ssh_user] = 'ubuntu'

        # Configure bootstrapping
        knife[:bootstrap_runs_chef_client] = true
        bootstrap_chef_version   "~> 0.10.0"

        # AWS access credentials
        knife[:aws_access_key_id]      = "XXXXXXXXXXX"
        knife[:aws_secret_access_key]  = "XXXXXXXXXXXXX"
```

#### Push to chef server

To send all the cookbooks and role to the chef server, visit your cluster_chef directory and run:

```ruby
        cd $CHEF_REPO_DIR
        mkdir -p $CHEF_REPO_DIR/site-cookbooks
        knife cookbook upload --all
        for foo in roles/*.rb ; do knife role from file $foo & sleep 1 ; done
```

You should see all the cookbooks defined in cluster_chef/cookbooks (ant, apt, ...) listed among those it uploads.

### Your first cluster

Let's create a cluster called 'demosimple'. It's, well, a simple demo cluster.

#### Create a simple demo cluster

Create a directory for your clusters; copy the demosimple cluster and its associated roles from cluster_chef:

```ruby
        mkdir -p $CHEF_REPO_DIR/clusters
        cp cluster_chef/clusters/{defaults,demosimple}.rb ./clusters/
        cp cluster_chef/roles/{big_package,nfs_*,ssh,base_role,chef_client}.rb  ./roles/
        for foo in roles/*.rb ; do knife role from file $foo ; done
```

Symlink in the cookbooks you'll need, and upload them to your chef server:

```ruby
        cd $CHEF_REPO_DIR/cookbooks
        ln -s         ../cluster_chef/site-cookbooks/{nfs,big_package,cluster_chef,cluster_service_discovery,firewall,motd}         .
        knife cookbook upload nfs big_package cluster_chef cluster_service_discovery firewall motd
```

#### AWS credentials

Make a cloud keypair, a secure key for communication with Amazon AWS cloud. cluster_chef expects a keypair named after its cluster -- this is a best practice that helps keep your environments distinct.

1. Log in to the "AWS console":http://bit.ly/awsconsole and create a new keypair named @demosimple@. Your browser will download the private key file.
2. Move the private key file you just downloaded to your .chef dir, and make it private key unsnoopable, or ssh will complain:

```ruby
mv ~/downloads/demosimple.pem $DOT_CHEF_DIR/demosimple.pem
chmod 600 $DOT_CHEF_DIR/*.pem
```

### Cluster chef knife commands

#### knife cluster launch

Hooray! You're ready to launch a cluster:

```ruby
    knife cluster launch demosimple homebase --bootstrap
</pre>

It will kick off a node and then bootstrap it. You'll see it install a whole bunch of things. Yay.

## Extended Installation Notes

### Set up Knife on your local machine, and a Chef Server in the cloud

If you already have a working chef installation you can skip this section.

To get started with knife and chef, follow the "Chef Quickstart,":http://wiki.opscode.com/display/chef/Quick+Start We use the hosted chef service and are very happy, but there are instructions on the wiki to set up a chef server too. Stop when you get to "Bootstrap the Ubuntu system" -- cluster chef is going to make that much easier.

### Cloud setup

If you can use the normal knife bootstrap commands to launch a machine, you can skip this step.

Steps:

* sign up for an AWS account
* Follow the "Knife with AWS quickstart": on the opscode wiki.

Right now cluster chef works well with AWS.  If you're interested in modifying it to work with other cloud providers, "see here":https://github.com/infochimps/cluster_chef/issues/28 or get in touch.
