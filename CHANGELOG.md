# v4.0.2: Parallel calls working once more
* Added Ironfan.parallelize, to run the basic cluster commands in parallel against their servers
* Make security_group range and group authorizations store only unique values

# v4.0.1: Minor bug-fixes
* Don't attempt to correlate the node volumes hash unless it's set
* RaidGroup declared by the DSL should get a name (so it can be indexed correctly)
* Volume.defaults is deprecated

# v4.0.0:  Major refactoring to allow multicloud support
* First pass at a provider plugin API, with EC2 as the working example.
* Removed role_implications: these can be handled by explicit ec2.security_group calls for now. See https://github.com/infochimps-labs/ironfan/wiki/Upgrading-to-v4 for more details.
* Added default_cloud flag to cloud statement (sets that cloud as the default one, if there are multiple clouds available), added use_cloud statement to compute components (cluster/facet/server) which overrides those defaults. There are plans for a command-line override, as well.

# v3.2.0: First refactoring pass in preparation for multi-cloud support
* Rebuilt the internal models of Ironfan to use gorillib's Field/Model/Builder architecture.
* [#145](https://github.com/infochimps-labs/ironfan/pull/145): node attribues should be 'normal', not 'override' -- they don't show up as printed on the node otherwise
* [#144](https://github.com/infochimps-labs/ironfan/pull/144): knife cluster ssh sets exit status based on commands' exit status
* [#139](https://github.com/infochimps-labs/ironfan/pull/139): Fix detection of hostname in cluster_launch

# v3.1.6
* [#136](https://github.com/infochimps-labs/ironfan/pull/136): Basic support for VPC
* cleanup of gemspec version constraints, including move to chef 0.10.10
* CentOS compatibility tweaks to several cookbooks

# v3.1.5: A bug with quoting in bootstrap scripts

* Bootstrap scripts with env vars were being interpolated twice, so the bootstrap script quoting was changed to use `'` (single-quote) semantics. I am a bit troubled, because I can't tell when this regression happened. I believe I introduced it while merging @gpaco's bootstrap scripts and didn't notice because the bug strikes most forcefully within the fenced-off 'Is ruby installed?' part. But there's a chance I just screwed over chef 0.10.04 users.

# v3.1.4: The inevitable post-launch tweaks

* Lots of documentation fixes, thanks @sya!
* Yard docs render pretty now (and quietly)
* Knife cluster kick now asks for sudo correctly -- enabling knife to do its password catching thing

# v3.1.1: I am Ironfan danananananabumbumbum

* 'ClusterChef has been renamed 'Ironfan'
* The 'Metachef' cookbook has been renamed 'Silverware'
* The 'Minidash' cookbook has been renamed 'Minidash'

You should reload your chef server:

    knife cookbook delete metachef dashpot
    knife cookbook upload --all
    rake roles

* You can now launch a cluster locally with vagrant!
  - follow the instructions in [ironfan-ci](https://github.com/infochimps-labs/ironfan-ci/blob/master/README-install.md)
  - set up a credentials set for your local machine (`cp -rp knife/example-credentials knife/local-credentials ; ln -nfs local-credentials knife/credentials`)
  - customize its `knife-org.rb` for your chef server
  - `knife cluster vagrant up sandbox-simple`

* Deprecated 'knife cluster foo nikko web 0' (many args) in favor of 'knife cluster foo nikko-web-0' (single arg). 
  - the latter still works, it just yells a lot.
  
* Am changing `--no-cloud` and `--no-chef` to `--cloud=false` and `--chef=false`, opening up room for a later `--cloud=rackspace` etc.

* many doc fixes, thanks @sya!


__________________________________________________________________________
__________________________________________________________________________

## v3.0.14: 

Big important change:

# ClusterChef is now Ironfan

Due to a polite request from outside, we are changing this project's name to not include the word 'Chef'.

It's now 'Ironfan', after Princess Iron Fan from the legend of Sun Wukong (Voyage to the West). The monkey hero Sun Wukong could not reach his destination without the help of the Princess's Iron Fan. The project helps you fan out across big iron in the sky -- and "You Can't Do B.I. without a Big Ironfan".

This weekend (2/18) everything in the ironfan family of everything will get regex-replaced as ironfan. We'll track both gems for the next push or so, but new versions of the gem will not be released after Feb 2012.

Other improvements/fixes:

* knife cluster proxy now accepts additional hosts to direct to proxy -- set Chef::Config[:cluster_proxy_patterns] to an array of additional glob-style strings. Use this with the route53 support for fun and profit - if your machines look like foo-server-0-internal.whatupchimpy.com, add Chef::Config[:cluster_proxy_patterns] = '*internal.whatupchimpy.com*' to your knife-org.rb -- now you can browse securely to the private interface of any machine your target can.
* FIX #76 -- `knife cluster kick` runs chef-client if the service is stopped. Fixes #76 . Also knife ssh will at its end show a bright red list of machines whose commands exited with a non-zero exit code -- useful when 1 out of 30 machines fails a knife cluster kick.
* A limited number of commands (ssh, show, kill) now run with no requirement of cloud anything (Relates to #28). Also worked around an annoying incompatibility with chef 0.10.8 (clients have a 'name') vs 0.10.40-and-prev (clients have a 'clientname'.
* examples all live in `ironfan-homebase` now.
* When you `knife cluster stop` a node, it sets `node[:state]` to 
* the cookbook linter now has its own project: [ironfan-scrubby](https://github.com/infochimps-labs/ironfan-scrubby). Along the way, 
  - some ability to cycle comments from the attributes file into node attribute docs in the `metadata.rb`.
  - added helpful links to the `README.md` template
* minor fix to the new `authorized_by` calls

## v3.0.11: We Raid at Dawn

* You can now assemble raid groups in the cluster definition:
  - node metadata instructing the volumes recipe to build the raid volume
  - marks the component volumes as non-mountable, in the appropriate raid group, etc
* Changed the order of `cluster_role` and `facet_role` in the run list. It now goes:
  - `:first`  roles (cluster then facet)
  - `:normal` roles (cluster then facet)
  - special roles: `cluster_role` then `facet_role`
  - `:last` roles (cluster then facet)
* knife cluster launch uses ClusterBootstrap, not knife's vanilla bootstrap.
* can now do group('group_that_wants').authorized_by_group('group_that_grants') so that in cluster A I can request access to cluster B without gaining its group myself.
* push the organization (if set) into the node metadata

## v3.0.10: Cloud fixes

* security groups are now created/updated in knife cluster sync. This can't help you apply then to a node afer launch though -- nothing can, the API doesn't allow it.
* clusters now all refer to an AMI named `ironfan-natty` by default, and to customizable roles `org_base`, `org_final` and `org_users` (where `org_base` has a role_implication for membership in the systemwide `org_base` security group)
* default facet instances is now 1 who knows why it wasn't always 1.
* minor linting of cluster before launching it
* bump to latest versions of oneiric AMIs thx @redbeard
* bootstrap fixes, oneiric support, more from @gchpaco


## v3.0.6: schism of cookbooks and tools

* cookbooks all now live in [their own repo](https://github.com/infochimps-labs/ironfan-homebase), organized according to opscode standard.
* gem is now split into `ironfan` (the libraries) and `ironfan-knife` (the chef plugins)
* private_key was passing its block to super, with bad results

## Changes from v2 => v3 [2011 October]

**The below-described changes are still in progress**

_________

Ironfan underwent a major upgrade with the last several commits.

* the `ironfan` tools -- the DSL, knife plugins, and bootstrap scripts -- have been split out of the  [ironfan repo](http://github.com/infochimps-labs/ironfan) into a [separate repo](http://github.com/infochimps-labs/ironfan-tools).
* The tools are now available as a gem -- `gem install ironfan`
* Cleaned up the code
* Standardized clusters & roles
* Standardized cookbooks

### Ironfan DSL Changes

The following behaviors have been removed:

* `use` -- **BREAKING** Was supposed to let me import another cluster definition into the one calling use. However, it didn't work as advertised, was clutter-y and was actively unpopular (issue #6). 
  - Until the usage of derived clusters becomes clear, say `merge!` on a hash instead.
  - We do default settings for you.
  - We *don't* put in any default roles (as the old `use :defaults` did).

* `cloud` -- **BREAKING** a bare `cloud` statement is meaningless: the *attributes* may be abstract, but the *values* are different for every provider. 
  - Anywhere you used to say `cloud`, say `ec2`: eg `ec2.flavor('t1.micro')` instead of `cloud.flavor('t1.micro')`.

* `chef_attributes` -- **BREAKING** replaced by `facet_role.override_attributes`, `facet_role.default_attributes` (or those methods on `cluster_role`.)

* `cluster_role_implication` -- **BREAKING** now called role_implications, brought in by default.

* `cluster.mounts_ephemeral_volumes` is now `cloud.mount_ephemerals`; it is not done by default.

### Knife Changes

Several knife scripts saw name changes to their params. If you have external scripts that call `knife cluster XXX` please update them. No futher changes to parameters are expected.

* `knife cluster kill` **only asks you once** whether to kill things -- there's no more `--really` flag.
* Standalone args now all properly have `--whatever` and `--no-whatever` forms.
* **BREAKING** The sync and kill commands both agree that `--chef` and `--cloud` are how to restrict their attention.


### Cookbook-affecting changes

* Standardized on `node[:cluster_name]`, `node[:facet_name]` and `node[:facet_index]` as the way to refer to the cluster, facet and server parts of a node's name. This replaces the way-too-many names for these: `node[:ironfan][:facet]` and `node[:cluster_role]` (use `node[:facet_name]`), `node[:ironfan][:index]` and `node[:cluster_role_index]` (use `node[:facet_index]`) .
* Ironfan family of cookbooks were updated accordingly.

#### hadoop_cluster cookbook

* The bootstrap recipes are gone. They may come back, but for now the dance is:
  - bring up the cluster ; by default the service state for all the daemons is [:disable, :stop].
  - run the `/etc/hadoop/conf/bootstrap_hadoop_namenode.sh` to format your HDFS
  - move the service state to '[:enable, :start]' and re-run chef client
  

#### Deprecated cookbooks

You must add `"#{ironfan_path}/deprecated-cookbooks"` to your cookbook_path in knife.rb if you would like to keep using

* `cluster_ebs_volumes` -- use `mountable_volumes` instead.

