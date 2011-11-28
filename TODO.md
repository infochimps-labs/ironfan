### From Nathan
- make ```knife cluster sync``` not create nodes/clients when cluster is down
- track global order of runlist additions, compile final list using that order
- syntactic sugar for ```server(0).fullname('blah')```
- rename provides_service to announces_service
    - backwards compatibility with WARNING (+ stacktrace on DEBUG)
    - ERROR for provides_service if not 'mycluster-service'

### Knife commands

* knife cluster kick fails if service isn't running

* make clear directions for installing `cluster_chef` and its initial use.



### Cookbook attribute refresh:

                          | flip fixed | temujin9 checked |
                          +------------+------------------+
        cassandra	  |            |                  |
        ec2               |            |                  |
        elasticsearch	  |            |                  |
        firewall	  |            |                  |
        flume             |            |                  |
        ganglia           |            |                  |
        graphite	  |            |                  |
        hadoop_cluster	  |            |                  |
        hbase             |            |                  |
        hive              |            |                  |
        jenkins           |            |                  |
        jruby             |            |                  |
        nfs               |            |                  |
        nodejs            |            |                  |
        papertrail	  |            |                  |
        pig               |            |                  |
        redis             |            |                  |
        resque            |            |                  |
        Rstats            |            |                  |
        statsd            |            |                  |
        zookeeper	  |            |                  |
        # meta:
        install_from	  |            |                  |
        motd              |            |                  |
        mountable_volumes |            |                  |
        provides_service  |            |                  |
        # Need thinkin':
        big_package	  |            |                  |
        cluster_chef      |            |                  |


### std cookbooks

#### integration

* apt: has a dashboard at http://{hostname}:3142/report


### Cookbook Munger

* update to-from comments in attributes.rb

### Concern Separation

Split cluster chef repo (or brightline how they would split) into:

* **cluster_chef-tools**:       a gem holding all the `knife cluster` commands.
* **cluster_chef-homebase**:    a repo just like you'd want as a home base (fork of http://github.com/opscode/chef-repo)
* **cluster_chef-cookbooks**:   holds the current contents of site-cookbooks and meta-cookbooks
* **vendor/opscode/cookbooks**: a git submodule of the opscode cookbooks repo

### provides_service

* should let me concisely refer to another cluster for a service (or use the current server)
* Timing issues in provides_service: be careful to invoke it during converge not config

### Minor Quibbles

* NFS server boostrapping
  - need to upgrade kernel, restart
* A 'safety catch' -- see https://github.com/infochimps/cluster_chef/issues/18#issuecomment-1194916

__________________________________________________________________________

to Bitch at opscode aboout

* open up your permissions API already dammit
* save opcode/cookbooks 
* metadata.rb -- make it useful on the community site or shoot it in the head.

__________________________________________________________________________

## 
## DONE
## 

### Environments

You can now say `environment :prod` (or whatever) in your clusters definition to apply that chef env to the node. You can apply at the cluster, facet or server level, with each overriding in turn.  By default, cluster is in the `_default` environment. You must add the environment outside cluster_chef -- by choice, it will not create it for you (we don't want typos creating environments).

### seamless stop-start support

* chef-client on bootup
  - when you stop/start machines their IP address changes, so must reconverge
* create chef node for me
* chef needs to converge twice on hadoop master
* dirs are fucked up under natty beause paths are /dev/xvdi not /dev/sdi

### cluster_chef DSL

* `role` and `recipe`
  - inject into the run_list directly
  - `cluster_role_implication`
  - clean up `first_boot.json`

### Minor quibbles

* `use defaults`
* `ephemeral drives` cleanup
* Fog routines should use the cluster's region always -- https://github.com/infochimps/cluster_chef/issues/54
* ebs volumes shouldn't complain if data_bag missing
