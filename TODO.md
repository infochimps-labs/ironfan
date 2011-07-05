First, about the stale recipe: the initial minimal DNA for a node is *not* in the machine's user-data, but in `/etc/chef/client-config.json` file

On startup:

* knife reads the cluster definition
* it puts a minimal amount of DNA into the node's user-data hash, passed along via the EC2 command.
* when the node starts up, it does the following:
  - makes an empy config hash.
  - If the node's `user-data` is valid JSON, merge it into the config hash.
  - if there is a file called chef-config.json, merge its contents into the config hash
  - if there is a file called client-config.json, merge it into the `:attributes ` sub-hash of the config.
* The outside part of the config (not the attributes field) has the info required for the node to discover its purpose and connect to the chef server (server url, validation_key, etc)
* If the `client-config.json` file is missing, it is created using the attributes subhash. Basically, this means that you can use that file to override anything set in the (immutable) user-data. Not the best thing, but it does work.
* The elements in the attributes field are passed to `json_attribs` to become chef node attributes, and **win out over anything in the git repo**.  This is bad.

## Proposal

Using a hadoop cluster called 'gibbon' (with namenode, jobtracker and workers) as an example:

### in `clusters/gibbon.rb`:

* physical configuration:
  - machine size, number of instances per facet, etc
  - external assets (elastic IP, ebs volumes)
* high-level assembly of roles and systems:
  - roles hadoop_namenode, nfs_client, flume_client, etc.
* important modifications:
  - cluster_chef::system_internals, mounts ebs volumes, etc
* override attributes:
  - heap size, rvm versions, etc.

### implement a a `knife cluster sync` command

  - pushes override attributes to the chef server
  - pushes the runlist to the chef server
* knife cluster bootstrap and knife cluster launch both invoke knife cluster sync.

### in `roles/`

* High-level roles that assemble recipes.
* Cluster and facet roles (`roles/gibbon_cluster.rb`, `roles/gibbon_namenode.rb`, etc) go away; override attributes go into the cluster.
  - currently, those files are typically empty and are badly cluttering the roles/ directory.
  - the cluster and facet override attributes should be together, not scattered in different files.
* roles shouldn't assemble systems. The contents of the `infochimps_chef/roles/plato_truth.rb` file belong in a *facet*.
 
### in the machine's user-data:

* the user-data should only have the minimal information required to join the chef server.
  - remove the run_list and aws fields
  - keep the cluster/facet/index identification
  - unfortunately, also have to keep the validation info
* Passing information in through the user-data is essential to be able to launch 30+ node clusters reliably. External surgery is problematic.
