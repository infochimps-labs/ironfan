
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

