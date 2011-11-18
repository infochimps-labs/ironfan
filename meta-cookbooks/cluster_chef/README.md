# cluster_chef chef cookbook

Installs/Configures cluster_chef

## Overview

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

* If you don't have exactly the semantics and datatype of the convention, don't use the convention.  That is, don't use `:port` and give it an array, or `:addr` and give it an email addr.

* use `foo_client` when you are a client of a service: so [:rails][:mysql_client][:host] to specify the hostname of your mysql server.

* There's an argument for saying "everything hadoop-related goes in /hadoop/{stuff}, and we symlink to its actual location. This way everything is the same from machine to machine". However, in this world you give up the integration hooks that being explicit gives you.  There's nothing stopping you from *also* creating those symlinks, but the core attributes (`tmp_dir`, `log_dir`, etc) should be explicit.

## Consuming services

* I am a web app and I want to connect to the right elasticsearch cluster.
  - `providers_of('elasticsearch', :for => :my_app)` gives me `providers_of("#{node[:my_app][:elasticsearch][:cluster_name]}-elasticsearch")` if `node[:my_app][:elasticsearch][:cluster_name]` is set, `providers_of("#{node[:cluster_name]}-elasticsearch")` otherwise.


## Also..

### Pedantic Style Points

#### Names:

* don't use the term `XX_path`. Use `xx_root` if it is only a base to house other named items, `xx_dir` if the directory serves a purpose (even if it is also a base for other named items).

default[:flume][:cluster_name]

default[:XXX][:aws_credential_handle] = 'main'
default[:XXX][:aws_credential_source] = :data_bag

    node[:chef][:chef_server][:addr]       = 1
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

      # if there is a value for node[:redis][:server][:addr] then it sets :addres => [that] on the provides_service call
      #
      :addres => [....] # will prevent the auto-adding

      ]
    )

## Attributes

* `[:server_tuning][:ulimit][:default]` - 
* `[:server_tuning][:ulimit][:@elasticsearch]` - 

## Recipes 

* `burn_ami_prep`            - Burn Ami Prep
* `cluster_webfront`         - Cluster Webfront
* `dedicated_server_tuning`  - Dedicated Server Tuning
## Integration

Supports platforms: debian and ubuntu



## License and Author

Author::                Philip (flip) Kromer - Infochimps, Inc (<coders@infochimps.com>)
Copyright::             2011, Philip (flip) Kromer - Infochimps, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

> readme generated by [cluster_chef](http://github.com/infochimps/cluster_chef)'s cookbook_munger
