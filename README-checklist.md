# Checklist for cookbooks, clusters and roles
 
## Naming Attributes

### File and Dir Aspects

A *file* is the full directory and basename for a file. A *dir* is a directory whose contents correspond to a single concern. A *root* is a prefix not intended to be used directly -- it will be decorated with suffixes to form dirs and files. A *basename* is only the leaf part of a file reference. Don't use the terms 'path' or 'filename'.

#### Application

* **log_file**, **log_dir**, **xx_log_file**, **xx_log_dir**:
  - default:        
    - if the log files will always be trivial in size, put them in `/var/log/:cookbook.log` or `/var/log/:cookbook/(whatever)`.
    - if it's a runit-managed service, leave them in `/etc/sv/:cookbook-:component/log/main/current`, and make a symlink from `/var/log/:cookbook-component` to `/etc/sv/:cookbook-:component/log/main/`.
    - If the log files are non-trivial in size, set log dir `/:scratch_root/:cookbook/log/`, and symlink `/var/log/:cookbook/` to it. 
    - If the log files should be persisted, place them in `/:persistent_root/:cookbook/log`, and symlink `/var/log/:cookbook/` to it. 
    - in all cases, the directory is named `.../log`, not `.../logs`. Also, never put things in `/tmp`.
    - Use the physical location for the `log_dir` attribute, not the /var/log symlink.
* **tmp_dir**:   
  - default:            `/:scratch_root/:cookbook/tmp/`
* **conf_dir**: 
  - default:            `/etc/:cookbook`
* **pid_file**, **pid_dir**: 
  - default:            pid_file: `/var/run/:cookbook.pid` or `/var/run/:cookbook/:component.pid`; pid_dir: `/var/run/:cookbook/`
  - instead of:         `job_dir`, `job_file`, `pidfile`, `run_dir`.
* **cache_dir**: 
  - default:            `/var/cache/:cookbook`.

* **data_dir**:
  - default:            `:persistent_root/:cookbook/:component/data`
  - instead of:         `datadir, `dbfile`, `dbdir`
* **journal_dir**: high-speed local storage for commitlogs and so forth. Can be deleted, but you'd rather it wasn't.
  - default:            `:scratch_root/:cookbook/:component/scratch`
  - instead of:         `commitlog_dir`  

* **home_dir**: Logical location for the system's code.
  - default: typically, leave it up to the package maintainer. Otherwise, `/usr/local/share/:cookbook` should be a symlink to the `install_dir` (see below).
  - instead of:         `xx_home` / `dir` alone / `install_dir`
* **install_dir**: The system's code, in case the home dir is a pointer to potential alternates.
  - default: `/usr/local/share/:cookbook-:version`
  - Make `home_dir` a symlink to this directory (eg home_dir `/usr/local/share/elasticsearch` links to install_dir `/usr/local/share/elasticsearch-0.17.8`).
  - Use this only if the code runs from this directory -- if you don't need the directory after the cookbook runs, use `src_dir` instead.
* **src_dir**: holds the compressed tarball, its expanded contents, and the compiled files when installing from source. Use this when you will run `make install` or equivalent and use the files elsewhere.
  - default:            `/usr/local/src/package_name-version`, eg `/usr/local/src/pig-0.9.tar.gz` leading to `/usr/local/src/pig-0.9/`
  - do not:             expand the tarball to `/usr/local/src/(whatever)` if it will actually be used from there; instead, use the `home_dir` convention described below. (As a guideline, I should be able to blow away `/usr/local/src` and everything still works).
* **deploy_dir**: deployed code that follows the capistrano convention. See more about deploy variables below.
  - the `:deploy_dir/shared` directory holds common files
  - releases are checked out to `:deploy_dir/releases/{sha}`
  - the operational release is a symlink to the right release: `:deploy_dir/current -> :deploy_dir/releases/xxx`.
  - do not:             use this when you mean `home_dir`.
* **bin_dir**:
  - default:            `/:home_dir/bin`

### Daemon Aspects

* **daemon_name** daemon's actual service name, if it differs from the component. For example, the `hadoop-namenode` component's daemon is `hadoop-0.20-namenode` as installed by apt.
* **daemon_state**:     one of the verbs acceptable to the Chef `service` resource: `:enable`, `:start`, etc.
* **num_xx_processes**, **num_xx_handlers** the number of separate top-level processes (distinct PIDs) or internal threads to run
  - instead of          `num_workers`, `num_servers`, `worker_processes`, `foo_threads`.
* **log_level** 
  - takes values        info, debug, warn
  - instead of          `verbose`, `verbosity`, `loglevel`
* **user**, **group**, **uid**, **gid** -- `user` is the user name.  The `user` and `group` should be strings, even the `uid` and `gid` should be integers.
  - instead of          username, group_name, using uid for user name or vice versa.
  - if there are multiple users, use a prefix: `launcher_user` and `observer_user`.

### Install / Deploy Aspects

* **version**:          if it's a simply-versioned resource that uses the `major.minor.patch-cruft` convention. Do not use unless this is true, and do not use the source control revision ID here.

* **release_url**:      URL for the release.
  - instead of:         install_url, package_url, being careless about partial vs whole URLs
* **release_file**:     Where to put the package.
  - default:            `/usr/local/src/package_file-version.ext`, eg `/usr/local/src/elasticsearch-0.17.8.tar.bz2`. 
  - don't use `/tmp` -- let me decide when to blow it away (and be idempotent with the install).
  - don't use a non-versioned URL or file name.
* **package_sha** or **package_md5** fingerprint
  - instead of:         `whatever_checksum`, `whatever_fingerprint`

* **deploy_repo_url**:  url for the repo, eg `git@github.com:infochimps/cluster_chef.git` or `http://github.com/infochimps/cluster_chef.git`
  - instead of:         `git_repo`, `git_url`
* **deploy_env**        production / staging / etc
* **deploy_strategy** 
* **deploy_dir**:       Only use `deploy_dir` if you are following the capistrano convention: see above.
* **deploy_revision**:  SHA or branch
  - instead of:         `git_revision`

* **apt_url**:          eg `http://archive.cloudera.com/debian`
* **apt_key**:          GPG key
* **force_distro**:     forces the distro (eg you are on natty but the apt repo only has maverick)

### Ports 

* **xx_port**:
  - *don't* use 'port' on its own.
  - examples: `thrift_port`, `webui_port`, `zookeeper_port`, `carbon_port` and `whisper_port`.
  - xx_port:
    - [:port]      =  5000  becomes :ports => {:port => "5000"}
  - xx_ports, if an array:
    - [:ports]     = [5000, 5001, 5002] becomes :ports => {:port_00 => "5000", :port_01 => "5000", :port_02 => "5000"}
    - [:foo_ports] = [5000, 5001, 5002] becomes :ports => {:foo_00 => "5000", :foo_01 => "5000", :foo_02 => "5000"}

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


## Cookbooks

* Dependencies are in metadata.rb, and include_recipe in the `default` recipe 
  - especially: `runit`, `java`, `cluster_service_discrovery`, `thrift`, `apt`
  - **include_recipe** is only used if putting it in the role would be utterly un-interesting. You *want* the run to break unless it's explicitly included the role. 
  - *yes*: `java`, `ruby`, `provides_service`, etc.
  - *no*:  `zookeeper:client`, `nfs:server`, or anything that will start a daemon

* (*see TODO*) Does `provides_service` uniformly handle referring to a foreign cluster for the service?

#### Recipes

* Naming:
  - foo/default    -- information shared by anyone using foo, including support packages, directories
  - foo/client     -- configure me as a foo client 
  - foo/server     -- configure me as a foo server
  - foo/aws_config -- cloud-specific settings
  
* Recipes shouldn't repeat their service name: `hbase:master` and not `hbase:hbase_master`; `zookeeper:server` not `zookeeper:zookeeper_server`.

#### Attribute Files

* The main attribute file should be named `attributes/default.rb`.
* If there are a sizeable number of tunable attributes (hadoop, cassandra), place them in `attributes/tuneables.rb`.
* ?? Place integration attribute *hooks* in `attributes/integration.rb` ??

## Integrations

### provides_service

### i_haz_a_log '/var/log/foo.log', :itz => :http

### i_haz_a_port '8080', :itz => :http

#### Jars

`i_can_haz_jars '/usr/lib/pig/pig.jar', '/usr/lib/pig/pig-nohadoop.jar'`


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
