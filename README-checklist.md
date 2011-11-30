# Checklist for cookbooks, clusters and roles

## Cookbooks

Ordinary cookbooks describe a single system, consisting of one or more components. For example, the `redis` cookbook has a `server` component (with a daemon and moving parts), and a `client` component (which is static).

You should crisply separate cookbook-wide concerns from component concerns. The server's attributes live in `node[:redis][:server]`, it is installed by the `redis::server` cookbook, and so forth.
  
You should also separate system configuration from multi-system integration. Cookbooks should provide hooks that are neighborly but not exhibitionist, and otherwise mind their own business. The `hadoop_cluster` cookbook describes hadoop, the `pig` cookbook pig, and the `zookeeper` cookbook zookeeper. The job of tying those components together (copying zookeeper jars into the pig home dir, or the port+addr of hadoop daemons) should be isolated.

### Recipes

* Naming:
  - `foo/recipes/default.rb`    -- information shared by anyone using foo, including support packages, directories
  - `foo/recipes/client.rb`     -- configure me as a foo client 
  - `foo/recipes/server.rb`     -- configure me as a foo server
  - `foo/recipes/ec2_conf`      -- cloud-specific settings
* Always include a `default.rb` recipe, even if it is blank. 
* *DO NOT* install daemons via the default cookbook, even if that's currently the only thing it does. Remember, a node that is a client -- or refers to any current or future component of the system -- will include the default recipe.
* Do not repeat the cookbook name in a recipe title: `hbase:master`, not `hbase:hbase_master`; `zookeeper:server`, not `zookeeper:zookeeper_server`.
* Use only `[a-z0-9_]` for cookbook and component names. Do not use capital letters or dashes. Keep names to fewer than 15 characters.

### Cookbook Dependencies

* Dependencies should be announced in metadata.rb, of course.
* *DO* remember to explicitly `include_recipe` for system resources -- `runit`, `java`, `provides_service`, `thrift` and `apt`.
* *DO NOT* use `include_recipe` unless putting it in the role would be utterly un-interesting. You *want* the run to break unless it's explicitly included the role. 
  - *yes*: `java`, `ruby`, `provides_service`, etc.
  - *no*:  `zookeeper:client`, `nfs:server`, or anything that will start a daemon
  Remember: ordinary cookbooks describe systems, roles and integration cookbooks coordinate them.
* `include_recipe` statements should only appear in recipes that are entry points. Recipes that are not meant to be called directly should assume their dependencies have been met.
* If a recipe is meant to be the primary entrypoint, it *should* include default, and it should do so explicitly: `include_recipe 'foo::default'` (not just 'foo'). 

### Templates

* *DO NOT* use node[:foo] in your recipes except in rare circumstances. Instead, say `variables :foo => node[:foo]`; this lets folks use that cookbook from elsewhere.

### Attributes
 
* Scope concerns by *cookbook* or *cookbook and component*. `node[:hadoop]` holds cookbook-wide concerns, `node[:hadoop][:namenode]` holds component-specific concerns.
* Attributes shared by all components sit at cookbook level, and are always named for the cookbook: `node[:hadoop][:log_dir]` (since it is shared by all its components).
* Component-specific attributes sit at component level (`node[:cookbook_name][:component_name]`): eg `node[:hadoop][:namenode][:service_state]`. Do not use a prefix (NO: `node[:hadoop][:namenode_handler_count]`)

#### Attribute Files

* The main attribute file should be named `attributes/default.rb`.
* If there are a sizeable number of tunable attributes (hadoop, cassandra), place them in `attributes/tuneables.rb`.
* ?? Place integration attribute *hooks* in `attributes/integration.rb` ??

* Be generic when you're *simple and alone*, descriptive when you're not. 
  - If a component has only one log file, call it 'log_file': `node[:foo][:server][:log_file]` and in general do not use a prefix.
  - If a component has more than one log_file, *always* use a prefix: `node[:foo][:server][:dashboard_log_file]` and `node[:foo][:server][:gc_log_file]`.

* If you don't have exactly the semantics and datatype of the convention, don't use the convention.  That is, don't use `:port` and give it a comma-separated string, or `:addr` and give it an email address.
* (*this advice will change as we figure out integration rules*: use `foo_client` when you are a client of a service: so [:rails][:mysql_client][:host] to specify the hostname of your mysql server.)
 
## Attribute Names

### Universal Aspects

### File and Dir Aspects

A *file* is the full directory and basename for a file. A *dir* is a directory whose contents correspond to a single concern. A *root* is a prefix not intended to be used directly -- it will be decorated with suffixes to form dirs and files. A *basename* is only the leaf part of a file reference. Don't use the terms 'path' or 'filename'.

Ignore the temptation to make a one-true-home-for-my-system, or to fight the package maintainer's choices. 

#### Application

* **home_dir**: Logical location for the cookbook's system code.
  - default: typically, leave it up to the package maintainer. Otherwise, `:prefix_root/share/:cookbook` should be a symlink to the `install_dir` (see below).
  - instead of:         `xx_home` / `dir` alone / `install_dir`
* **prefix_root**: A container with directories bin, lib, share, src, to use according to convention
  - default: `/usr/local`.
* **install_dir**: The cookbook's system code, in case the home dir is a pointer to potential alternates.
  - default: `:prefix_root/share/:cookbook-:version` ( you don't need the directory after the cookbook runs, use `:prefix_root/share/:cookbook-:version` instead, eg `/usr/local/src/tokyo_tyrant-xx.xx`)
  - Make `home_dir` a symlink to this directory (eg home_dir `/usr/local/share/elasticsearch` links to install_dir `/usr/local/share/elasticsearch-0.17.8`).
* **src_dir**: holds the compressed tarball, its expanded contents, and the compiled files when installing from source. Use this when you will run `make install` or equivalent and use the files elsewhere.
  - default:            `:prefix_root/src/:system_name-:version`, eg `/usr/local/src/pig-0.9.tar.gz`
  - do not:             expand the tarball to `:prefix_root/src/(whatever)` if it will actually be used from there; instead, use the `install_dir` convention described above. (As a guideline, I should be able to blow away `/usr/local/src` and everything still works).
* **deploy_dir**: deployed code that follows the capistrano convention. See more about deploy variables below.
  - the `:deploy_dir/shared` directory holds common files
  - releases are checked out to `:deploy_dir/releases/{sha}`
  - the operational release is a symlink to the right release: `:deploy_dir/current -> :deploy_dir/releases/xxx`.
  - do not:             use this when you mean `home_dir`.

* **scratch_roots**, **persistent_roots**: an array of directories spread across volumes, with expectations on persistence
  - `scratch_root`s have no guarantee of persistence -- for example, stop/start'ing a machine on EC2 destroys the contents of its local (ephemeral) drives. `persistent_root`s have the *best available* promise of persistance: if permanent (eg EBS) volumes are available, they will exclusively populate the `persistent_root`s; but if not, the ephemeral drives are used instead.
  - these attributes are provided by the `mountable_volume` meta-cookbook and its appropriate integration recipe. Ordinary cookbooks should always trust the integration cookbook's choices (or visit the integration cookbook to correct them).
  - each element in `persistent_roots` is by contract on a separate volume, and similarly each of the `scratch_roots` is on a separate volume. A volume *may* be in both scratch and persistent (for example, there may be only one volume!).
  - the singular forms  **scratch_root** and **persistent_root** are provided for your convenience and always correspond to `scratch_roots.first` and `persistent_roots.first`. This means lots the first named volume is picked on the heaviest -- if you don't like that, choose explicitly (but not randomly, or you won't be idempotent).


* **log_file**, **log_dir**, **xx_log_file**, **xx_log_dir**:
  - default:        
    - if the log files will always be trivial in size, put them in `/var/log/:cookbook.log` or `/var/log/:cookbook/(whatever)`.
    - if it's a runit-managed service, leave them in `/etc/sv/:cookbook-:component/log/main/current`, and make a symlink from `/var/log/:cookbook-component` to `/etc/sv/:cookbook-:component/log/main/`.
    - If the log files are non-trivial in size, set log dir `/:scratch_root/:cookbook/log/`, and symlink `/var/log/:cookbook/` to it. 
    - If the log files should be persisted, place them in `/:persistent_root/:cookbook/log`, and symlink `/var/log/:cookbook/` to it. 
    - in all cases, the directory is named `.../log`, not `.../logs`. Never put things in `/tmp`.
    - Use the physical location for the `log_dir` attribute, not the /var/log symlink.
* **tmp_dir**:   
  - default:            `/:scratch_root/:cookbook/tmp/`
  - Do not put a symlink or directory in `/tmp` -- something else blows it away, the app recreates it as a physical directory, `/tmp` overflows, pagers go off, sadness spreads throughout the land.
* **conf_dir**: 
  - default:            `/etc/:cookbook`
* **bin_dir**:
  - default:            `/:home_dir/bin`
* **pid_file**, **pid_dir**: 
  - default:            pid_file: `/var/run/:cookbook.pid` or `/var/run/:cookbook/:component.pid`; pid_dir: `/var/run/:cookbook/`
  - instead of:         `job_dir`, `job_file`, `pidfile`, `run_dir`.
* **cache_dir**: 
  - default:            `/var/cache/:cookbook`.

* **data_dir**:
  - default:            `:persistent_root/:cookbook/:component/data`
  - instead of:         `datadir, `dbfile`, `dbdir`
* **journal_dir**: high-speed local storage for commitlogs and so forth. Can be deleted, though you may rather it wasn't.
  - default:            `:scratch_root/:cookbook/:component/scratch`
  - instead of:         `commitlog_dir`  

### Daemon Aspects

* **daemon_name**:      daemon's actual service name, if it differs from the component. For example, the `hadoop-namenode` component's daemon is `hadoop-0.20-namenode` as installed by apt.
* **daemon_states**:    an array of the verbs acceptable to the Chef `service` resource: `:enable`, `:start`, etc.
* **num_xx_processes**, **num_xx_threads** the number of separate top-level processes (distinct PIDs) or internal threads to run
  - instead of          `num_workers`, `num_servers`, `worker_processes`, `foo_threads`.
* **log_level**
  - application-specific; often takes values info, debug, warn
  - instead of          `verbose`, `verbosity`, `loglevel`
* **user**, **group**, **uid**, **gid** -- `user` is the user name.  The `user` and `group` should be strings, even the `uid` and `gid` should be integers.
  - instead of          username, group_name, using uid for user name or vice versa.
  - if there are multiple users, use a prefix: `launcher_user` and `observer_user`.

### Install / Deploy Aspects

* **release_url**:      URL for the release.
  - instead of:         install_url, package_url, being careless about partial vs whole URLs
* **release_file**:     Where to put the release.
  - default:            `:prefix_root/src/system_name-version.ext`, eg `/usr/local/src/elasticsearch-0.17.8.tar.bz2`. 
  - do not use `/tmp` -- let me decide when to blow it away (and make it easy to be idempotent).
  - do not use a non-versioned URL or file name.
* **release_file_sha** or **release_file_md5** fingerprint
  - instead of:         `whatever_checksum`, `whatever_fingerprint`
* **version**:          if it's a simply-versioned resource that uses the `major.minor.patch-cruft` convention. Do not use unless this is true, and do not use the source control revision ID.

* **plugins**:          array of system-specific plugins

use `deploy_{}` for anything that would be true whatever SCM you're using; use
`git_{}` (and so forth) where specific to that repo.

* **deploy_env**        production / staging / etc
* **deploy_strategy**   
* **deploy_user**       user to run as
* **deploy_dir**:       Only use `deploy_dir` if you are following the capistrano convention: see above.

* **git_repo**:  url for the repo, eg `git@github.com:infochimps/cluster_chef.git` or `http://github.com/infochimps/cluster_chef.git`
  - instead of:         `deploy_repo`, `git_url`
* **git_revision**:  SHA or branch
  - instead of:         `deploy_revision`

* **apt/{repo_name}**   Options for adding a cookbook's apt repo.
  - Note that this is filed under *apt*, not the cookbook.
  - Use the best name for the repo, which is not necessarily the cookbook's name: eg `apt/cloudera/{...}`, which is shared by hadoop, flume, pig, and so on.
  - `apt/{repo_name}/url` -- eg `http://archive.cloudera.com/debian`
  - `apt/{repo_name}/key` -- GPG key
  - `apt/{repo_name}/force_distro` -- forces the distro (eg, you are on natty but the apt repo only has maverick)

### Ports 

* **xx_port**:
  - *do not* use 'port' on its own.
  - examples: `thrift_port`, `webui_port`, `zookeeper_port`, `carbon_port` and `whisper_port`.
  - xx_port: `default[:foo][:server][:port] =  5000`
  - xx_ports, if an array: `default[:foo][:server][:ports] = [5000, 5001, 5002]` 

* **addr**, **xx_addr**
  - if all ports bind to the same interface, use `addr`. Otherwise, do *not* use `addr`, and use a unique `foo_addr` for each `foo_port`.
  - instead of:         `hostname`, `binding`, `address`

* Want some way to announce my port is http or https.
* Need to distinguish client ports from service ports. You should be using cluster service discovery anyway though.

### Application Integration

* **jmx_port**

### Tunables

* **XX_heap_max**, **xx_heap_min**, **java_heap_eden**
* **java_home** 
* AVOID **java_opts** if possible: assemble it in your recipe from intelligible attribute names.

### Nitpicks

* Always put file modes in quote marks: `mode "0664"` not `mode 0664`.

## Announcing Aspects 

If your app does any of the following, 

* **services**    -- Any interesting long-running process.
* **ports**       -- Any reserved open application port
  - *http*:          HTTP application port
  - *https*:         HTTPS application port
  - *internal*:      port is on private IP, should *not* be visible through public IP
  - *external*:      port *is* available through public IP
* metric_ports:
  - **jmx_ports** -- JMX diagnostic port (announced by many Java apps)
* **dashboards**  -- Web interface to look inside a system; typically internal-facing only, and probably not performance-monitored by default.
* **logs**        -- um, logs. You can also announce the logs' flavor: `:apache`, `log4j`, etc.
* **scheduleds**  -- regularly-occurring events that leave a trace
* **exports**     -- jars or libs that other programs may wish to incorporate
* **consumes**    -- placed there by any call to `discover`.

### Dummy aspects

Integration cookbooks that announce as

* Elastic Load Balancers


## Clusters

* Describe physical configuration:
  - machine size, number of instances per facet, etc
  - external assets (elastic IP, ebs volumes)
* Describe high-level assembly of systems via roles: `hadoop_namenode`, `nfs_client`, `flume_client`, etc.
* Describe important modifications, such as `cluster_chef::system_internals`, mounts ebs volumes, etc
* Describe override attributes:
  - `heap size`, rvm versions, etc.

* roles and recipes 
  - remove `cluster_role` and `facet_role` if empty
  - are not in `run_list`, but populated by the `role` and `recipe` directives
* remove big_package unless it's a dev machine (sandbox, etc)

## Roles

Roles define the high-level assembly of recipes into systems

* override attributes go into the cluster.
currently, those files are typically empty and are badly cluttering the roles/ directory.
the cluster and facet override attributes should be together, not scattered in different files.
roles shouldn't assemble systems. The contents of the infochimps_chef/roles/plato_truth.rb file belong in a facet.

* Deprecated: 
  - Cluster and facet roles (`roles/gibbon_cluster.rb`, `roles/gibbon_namenode.rb`, etc) go away
  - roles should be service-oriented: `hadoop_master` considered harmful, you should explicitly enumerate the services

