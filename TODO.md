### seamless stop-start support

* chef-client on bootup
  - when you stop/start machines their IP address changes, so must reconverge

* create chef node for me

* chef needs to converge twice on hadoop master

* dirs are fucked up under natty beause paths are /dev/xvdi not /dev/sdi

### cluster_service_discovery

* should let me concisely refer to another cluster for a service (or use the current server)
* Wait for service to announce

### cluster_chef DSL

* `role` and `recipe`
  - inject into the run_list directly
  - `cluster_role_implication`
  - clean up `first_boot.json`


### Minor quibbles

* NFS server boostrapping
  - need to upgrade kernel, restart

* A 'safety catch' -- see https://github.com/infochimps/cluster_chef/issues/18#issuecomment-1194916

* `use defaults`
* `ephemeral drives` cleanup

* Fog routines should use the cluster's region always -- https://github.com/infochimps/cluster_chef/issues/54

* ebs volumes shouldn't complain if data_bag missing

### Concern Separation

Cluster chef currently consists of the following separate(able) concerns:

* **cluster_chef tools**
  - the DSL that lets you define clusters
  - the knife commands which use that DSL
  - optional bootstrap scripts for a machine image that can then launch bootstrap-less
* **cluster-oriented cookbooks**
  - `cluster_service_discovery` (recipes to let clusters discover services using chef-server's search)
  - ?others?
* **cloud utility cookbooks**
  - motd, system_internals (swappiness, ulimit, etc)
* **big data cookbooks** (hadoop, cassandra, redis, etc):
  - cookbooks
  - roles
  - clusters

I think it's time to separate those into at least two repos.

REQUEST FOR COMMENTS: 

#### Division of concerns

It's clear that the cluster_chef tools and the big data cookbooks should be divorced.

Proposed:

* `cluster_chef` holds only the DSL, knife commands, and bootstrap scripts -- basically the stuff in `lib/`, along with the gemspec etc.
* `cluster_chef-systems` -- holds cookbooks, roles and example clusters that use them. 
  - Utility cookbooks (`cluster_service_discovery`, motd, etc) and system cookbooks(hadoop, cassandra, etc) are housed in two separate folders. 
  - The standard layout would just include the cookbooks, but a cluster-oriented approach demands that the roles travel along too
* (possibly) `cluster_chef-chef-repo` (??better name, anyone??) -- a fork of https://github.com/opscode/chef-repo that integrates the above

#### Handling of cookbooks that originate from opscode-cookbooks

Right now we *copy* standard cookbooks from opscode's repo into the `cookbooks` directory. This lets us version them separately, but means we have to track them, and could cause conflicts with the majority of people who will be pulling from opscode-cookbooks already.

1. omit entirely, but list as dependencies (my vote)
2. `git subtree` pull them into the cluster_chef-cookbooks repo
3. copy them in as we've been doing
4. `git submodule` opscode-cookbooks and symlink

#### Organization of cookbooks repo

Opscode recommends a [standard layout for your chef repo](https://github.com/opscode/chef-repo). We should make the new arrangement work seamlessly within that structure.

The new layout should 
* easy to integrate if you have your own existing chef-repo
* straightforward for a new chef user to adopt
* either mirror or be what we actually use

Revised proposal:

```
  clusters/                 
    { actual clusters }
  roles/               
    { roles }
    { symlinks to things in vendor/cluster_chef/roles }
  
  site-cookbooks/
    { directories holding internal cookbooks }
    
  cookbooks/ 
    { symlinks into vendor/opscode-cookbooks }
    { symlinks into vendor/cluster_chef-systems/site-cookbooks }
    
  vendor/
    opscode/cookbooks/      # git submodule of https://github.com/opscode/cookbooks
    cluster_chef-systems/   # git submodule of https://github.com/infochimps/cluster_chef-systems
      site-cookbooks/         # hadoop, cassandra, cluster_service_discovery, etc.
      roles/
      examples/
        clusters/           # example clusters
        roles/              # roles (if any) needed for just the example clusters

  .chef/                    # knife config, keypairs, etc
  certificates/
  config/
  data_bags/
  environments/    
```

