## DESCRIPTION:

## REQUIREMENTS:

## ATTRIBUTES:

## USAGE:

There are many aspects shared by the great majority of installed systems. For example, each of these is an example of what we'll call *aspects*:
* I launch these daemons
* I log to this directory
* I listen on these ports 
* ... and much more.

Wouldn't it be nice if
* announcing I implemented a system meant that
  - my monitoring service added a dashboard for that system?
  - the motd on the machine announced that?
* announcing I had a log directory meant that 
  - the log rotation/archiving system (whatever it is) noticed started rotating and archiving my logs?
  - A graph was added to the service's monitoring dashboard for free space on that device?
  - if it is not just any log but specifically a web log, a standard listener was attached that counted the rate of requests, 200s, 404s and so forth?
* announcing ports
  - set up the firewall and security groups correspondingly
  - set a monitor that pinged the port for uptime and latency

If you make those aspects standardized and predictable, you can decorate each aspect with decoupled *concerns*, such as logging, monitoring, dashboarding and discovery. The key is to make integration *inevitable*. No more forgetting to rotate or monitor a service, or having a config change over here screw up an integration over there.

__________________________________________________________________________

Attributes are scoped by *cookbook* and then by *component*.
* If I declare `i_haz_a_service_itz('redis)`, it will look in `node[:redis]`.
* If I declare `i_haz_a_service_itz('hadoop-namenode')`, it will look in `node[:hadoop]` for cookbook-wide concerns and `node[:hadoop][:namenode]` for component-specific concerns.

* The cookbook scope is always named for its cookbook. Its attributes live in`node[:cookbook_name]`.
  - if everything in the cookbook shares a concern, it sits at cookbook level. So the hadoop log directory (shared by all its components) is at `(scratch_root)/hadoop/log`.
* If there is only one component, it can be implicitly named for its cookbook. In this case, it is omitted: the component attributes live in `node[:cookbook_name]` (which is the same as the component name).
* If there are multiple components, they will live in `node[:cookbook_name][:component_name]` (eg `[:hadoop][:namenode]` or `[:flume][:master]`. In file names, these become `(whatever)/cookbook_name/component_name/(whatever)`; in other cases they are joined as `cookbook_name-component_name`.

Being opinionated means we can be predictable and inevitable.

* The `ntp` cookbook has a `server` component, only. 
  - declare it as `i_haz_a_service_itz(:ntp)`.
  - name its recipe `ntp`, in the file `ntp/default.rb`.
  - name its daemon `ntp`.
  - access its attributes as `node[:ntp][:whatever]`.

* The `redis` cookbook has a `server` component (with a daemon and moving parts), and a `client` component (which is static).
  - 
  - *avoid* installing a daemon via the default cookbook.

* The `jenkins` cookbook has a `node` component and a `master` component; both exhibit server-like behavior.  For the `node` component,
  - declare it as `i_haz_a_service_itz(:jenkins, :node)`
  - access component-specific attributes as `default[:jenkins][:node][:whatever]`, etc.
  - name its recipe `jenkins::node`
  - name its daemon `jenkins-node`
  - use the helpers that scope its directories under `(concern)/jenkins/node`
Similarly, declare the master with `i_haz_a_service_itz(:jenkins, :master)`, and the recipes, daemons and dirs accordingly.

If things are simple, you get magic: declare `i_haz_a_service_itz(:jenkins, :node)`. An attribute `default[:jenkins][:node][:log_file]` will decorate the haz_service call with `:log_files => {:main => (that)}`. An attribute `default[:jenkins][:node][:stderr_log_file] = (this)` and `default[:jenkins][:node][:stdout_log_file] = (that)` implies  `:log_files => {:stdout => (this), :stderr => that}`.
* if you don't want magic, it's as easy as saying `:log_files => {}`.
* If things aren't simple, you have to be explicit: `:log_files => { :main => default[:jenkins][:node][:stderr_log_file], :weird => default[:jenkins][:node][:some_other_file_to treat_as_such]}`.
* The magic is a little magical but not a lot magical. A simple rule like 'we look for `log_file` or `(anything)_log_file` is OK. A rule like "we also look for `(anything)_?log_files` and if its an array we do this but if it's a hash we do that" is not OK.

* be generic when you're simple, descriptive when you're not: so, [:foosvc][:port] good, [:foosvc][:foosvc_port] (as the only one it serves) bad, [:foosvc][:dashboard_port] and [:foosvc][:client_port] good.

* If you don't have exactly the semantics and datatype of the convention, don't use the convention.  That is, don't use `:port` and give it an array, or `:address` and give it an email address.

* use `foo_client` when you are a client of a service: so [:rails][:mysql_client][:host] to specify the hostname of your mysql server.

* There's an argument for saying "everything hadoop-related goes in /hadoop/{stuff}, and we symlink to its actual location. This way everything is the same from machine to machine". However, in this world you give up the integration hooks that being explicit gives you.  There's nothing stopping you from *also* creating those symlinks, but the core attributes (`tmp_dir`, `log_dir`, etc) should be explicit.

## Provides Service items and their Magic Attributes

### File and Dir Aspects

A *file* is the full directory and basename for a file. A *dir* is a directory whose contents correspond to a single concern. A *root* is a prefix not intended to be used directly -- it will be decorated with suffixes to form dirs and files. A *basename* is only the leaf part of a file reference. Don't use the terms 'path' or 'filename'.

#### Application

* **log_files**, **log_dirs**:  
  - auto-discovery:     `log_file` or `xx_log_file`; `log_dir`, `xx_log_dir`, `log_dirs` or `xx_log_dirs`.
  - default:        
    - if the log files will always be trivial in size, put them in `/var/log/:cookbook.log` or `/var/log/:cookbook/(whatever)`.
    - if it's a runit-managed service, leave them in `/etc/sv/:cookbook-:component/log/main/current`, and make a symlink from `/var/log/:cookbook-component` to `/etc/sv/:cookbook-:component/log/main/`.
    - If the log files are non-trivial in size, set log dir `/:scratch_root/:cookbook/log/`, and symlink `/var/log/:cookbook/` to it. 
    - If the log files should be persisted, place them in `/:persistent_root/:cookbook/log`, and symlink `/var/log/:cookbook/` to it. 
    - in all cases, the directory is named `.../log`, not `.../logs`. Also, never put things in `/tmp`.
    - Use the physical location for the `log_dir` attribute, not the /var/log symlink.
* **tmp_dir**:   
  - auto-discovery:     `tmp_dir`, `tmp_dirs`.
  - default:            `/:scratch_root/:cookbook/tmp/`
* **conf_dir**: 
  - default:            `/etc/:cookbook/conf`
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

* **src_dir**: location of the compressed tarball, its expanded contents, and the compiled files when installing from source. Use this when you will run `make install` or equivalent and use the files elsewhere.
  - default:            `/usr/local/src/package_name-version`, eg `/usr/local/src/pig-0.9.tar.gz` leading to `/usr/local/src/pig-0.9/`
  - do not:             expand the tarball to `/usr/local/src/(whatever)` if it will actually be used from there; instead, use the `home_dir` convention described below. (As a guideline, I should be able to blow away `/usr/local/src` and everything still works).
* **home_dir**: Where the system's code resides. Typically only cookbook-level.
  - typically, leave it up to the package maintainer.
  - if installed directly:
    - put it physically in `/usr/local/share/:cookbook-:version`, but don't refer to this directory directly (eg `/usr/local/share/elasticsearch-0.17.8/`)
    - make a symlink `/usr/local/share/:cookbook` pointing to it, and use that as the `home_dir` (eg `/usr/local/share/elasticsearch => /usr/local/share/elasticsearch-0.17.8`).
  - instead of:         `xx_home` / `dir` alone / `install_dir`
* **deploy_dir**: Used for deployed code that follows the capistrano convention. See more about deploy variables below.
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

### Deploy Aspects

* **version**:          if it's a simply-versioned resource that uses the `major.minor.patch-cruft` convention. Do not use unless this is true, and do not use the source control revision ID here.

* **package_url_root**: URL for the package. Glue the **package_url** together using the version
  - instead of:         install_url, package_url_base, being careless about partial vs whole URLs
* **package_file**:     Where to put the package.
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

This needs some more thinking. 


* **ports**: hash of 
  - auto-discovery:     `port` or `xx_port`: `ssl_port`, `thrift_port`, `web_port`, `webui_port`, `zookeeper_port`, `carbon_port` and `whisper_port`.
  - need some way to signal if it binds to any address besides the `local_ip`.
  - port or xx_port:
    - [:port]      =  5000  becomes :ports => {:port => "5000"}
  - ports or xx_ports, if an array:
    - [:ports]     = [5000, 5001, 5002] becomes :ports => {:port_00 => "5000", :port_01 => "5000", :port_02 => "5000"}
    - [:foo_ports] = [5000, 5001, 5002] becomes :ports => {:foo_00 => "5000", :foo_01 => "5000", :foo_02 => "5000"}
  - We always refer to `port`. If you need CIDR-style references you're on your own.

* **host**: 
  - instead of:         `hostname`, `binding`, `address`

* Want some way to announce my port is http or https.
* Need to distinguish client ports from service ports. You should be using cluster service discovery anyway though.

### Application Integration

* **jmx_port**
* **Java options**: `XX_java_heap_max`, `java_heap_min`, `java_home`, `java_heap_eden`, `java_opts`
* **tunables**

## Consuming services

* I am a web app and I want to connect to the right elasticsearch cluster.
  - `providers_of('elasticsearch', :for => :my_app)` gives me `providers_of("#{node[:my_app][:elasticsearch][:cluster_name]}-elasticsearch")` if `node[:my_app][:elasticsearch][:cluster_name]` is set, `providers_of("#{node[:cluster_name]}-elasticsearch")` otherwise.


## Also..

### Pedantic Style Points

#### Names:

* Names for cookbooks and components must only consist of `a-z0-9_`. Do not use capital letters or dashes.
* Don't repeat the cookbook name in the component name: `hbase` cookbook should have a `regionserver` component, not an `hbase_regionserver` component.

#### Do nots:

* don't use the term `XX_path`. Use `xx_root` if it is only a base to house other named items, `xx_dir` if the directory serves a purpose (even if it is also a base for other named items).




default[:flume][:cluster_name]

default[:XXX][:aws_credential_handle] = 'main'
default[:XXX][:aws_credential_source] = :data_bag

    node[:chef][:chef_server][:address]       = 1
    node[:chef][:chef_server][:webui_port]    = 1
    node[:chef][:chef_server][:knife_port]    = 1
         .. becomes :ports => { :webui => xx, :knife => xx}

    node[:redis][:redis_server][:port] = xx
         .. becomes :ports => { :default => xx }

    node[:redis][:redis_server][:log_file] = xx

    node[:redis][:redis_server][:log_dir] = xx

    node[:hadoop][:namenode][:log_file]                  = xx # holds stderr
    node[:hadoop][:namenode][:some_other_dumb_file_that_should_also_get_treated_likewise] = xx # holds stdout

         if I say this, I *must* supply any magic values explicitly
    i_haz_a_service_itz('namenode',
      :log_files => [node[:hadoop][:namenode][:log], '/some/other/dumb_file_that_should_also_get_treated_likewise']
      )

    [:apache][:user]
         ...because that lets me say this to be non-magical.
    i_haz_a_service_itz 'namenode', :log_files => []


         this will take my cluster_name as the default scope (or I can override??)

    i_haz_a_service_itz('redis_server',

      # if there is a value for node[:redis][:redis_server][:address] then it sets :addresses => [that] on the provides_service call
      #
      :addresses => [....] # will prevent the auto-adding

      ]
    )

