# v4.10.3
* Tightening version constraints on excon, to avoid bad interaction between it & fog

# v4.10.2
* Adding creator tag to Machines (thanks @brandonbell)
* Bumping gorillib dependency to 0.5.0
* Removed old webinar notice from README

# v4.10.1
* Fixing bug in server role assignment (doesn't use cluster_role for some reason)

# v4.10.0
* Updating automatic roles to "#{name}-cluster" and "#{name}-facet", to avoid name collision with conventional roles (thanks, @jessehu)
* Added newly-ebs optimizeable instances to approved list (thanks @mrflip)

# v4.9.10
* fixing up file permissions (was causing glitch for bundles installed as root)

# v4.9.9
* further fixes to tell_you_thrice, noted need for specs

# v4.9.8
* fixing rescue block in tell_you_thrice

# v4.9.7
* cluster_stop: turning off aggregates? and prepares?

# v4.9.6
* cluster_kill: turning off aggregates?

# v4.9.5
* generalizing tell_you_thrice from ec2/machine
* cleaner message in rescue of tell_you_thrice

# v4.9.4
* ec2/machine: fixing debug output (duh)

# v4.9.3
* cluster_launch: cleaning up duplication and misinformation
* ec2/machine: cleaning up output on launch

# v4.9.2
* Ec2::Machine: trying a more brute-force solution to 'server went away' bug

# v4.9.1
* adding missed rbvmomi dependency

# v4.9.0
* initial vSphere support (thanks @brandonbell) - see lib/ironfan/dsl/vsphere and lib/ironfan/provider/vsphere for more info

# v4.8.7
* ec2/machine: fixing stop and start to wait for all valid end-states

# v4.8.6
* Gemfile: removing stale grit dependency (breaks Cygwin build due to stale posix-thread incompatibility)

# v4.8.5
* Added the m3 flavors to ec2_flavor_info (thanks @rottmanj)

# v4.8.4
* Fixing relevant? semantics in cluster_stop and cluster_start

# v4.8.3
* Bogus servers should not be killable (fixes #250)
* Style guide corrections ('&&', not 'and'; don't use single-letter variable names)
* Also fixed a thing where security groups enumeration would die if a bogus server existed that's bit me before
* Reviewed other knife cluster commands and made them not tolerate bogosity either

# v4.8.2
* Launch EBS-optimized boxen on EC2

# v4.8.1
* ec2::machine: increasing wait interval, to reduce potential for intermittent errors to bomb run

# v4.8.0
* Cleaning up Gemfile and Gemfile.lock to solidify dependencies

# v4.7.7
* Allow per-ephemeral-disk options using :disks attribute (thanks @nickmarden)

# v4.7.6
* adding chef-client-nonce invocation to knife cluster kick

# v4.7.5
* cluster_launch: correcting public_target to public_hostname

# v4.7.4
* Add configuration for us-west-2 ubuntu precise AMIs (thanks @msaffitz)

# v4.7.3
* cluster ssh was broken for VPC instances, this will fix a few bugs (fixes #236, thanks @gwilton)
* cluster_ssh & cluster_launch: cleaning up SSH usage to handle VPC
* Enhanced IP enhanced: adds auto_elastic_ip DSL and detection, mutually exclusive with regular elastic_ip (thanks @schade)

# v4.7.2
* elastic_ip: ensuring that elastic IPs work with VPC instances (thanks @schade)

# v4.7.1
* Cleaning up omnibus usage to link embedded bin, ruby into default $PATHs, rather than use /etc/environment to try tweaking (doesn't hit a large number of programs)
* Launched machines should announce their state as "started"

# v4.7.0:
(@nickmarden rocks the house again)
* Added support for "prepare" phase, prior to any machine-specific actions
* Move security group creation and authorization assurance to prepare phase (fixes #189)
* Allow user/group-style security group references (fixes #207)
* Move keypair creation to prepare phase

# v4.6.2:
* Added a -f/--with-facet option to knife cluster list

# v4.6.1:
* Fixes nested array bug when computing list of AZs for an ELB (thanks @nickmarden)
* Cleaning up overzealous Elastic IP inclusion (alternative fix to #222, thanks @nickmarden)

# v4.6.0:
* Elastic IP attachment and SSH support (changes ec2.public_ip to ec2.elastic_ip for clarity - thanks @schade)
* Expanded development dependencies, to allow avoiding bundler verbosity bug by rolling back to older version

# v4.5.2:
* 'knife cluster launch --bootstrap' should ensure that Chef::Config[:environment] is set, just as 'knife cluster bootstrap' does
* Cleaning up knife commands to skip bogus servers (fixes #213)
* EXPERIMENTAL: Adding (cross-platform) ironfaned chef omnibus bootstrap

# v4.5.1:
* Clean up on 12.04 template - do dist-upgrade, include omnibus bin in $PATH, nicer first-boot.json
* Removing superfluous raise on duplicate machines during load

# v4.5.0: upgraded to 12.04 bootstrap
* First stab at 12.04 from @nickmarden's pull #171 - uses omnibus, not autobuild ruby
* Removed bad 11.10 bootstrap script - used incompatible ruby install
* Cleanup knife cluster proxy (may help #162)
* Added ec2 hints for ohai (fixes #204)
* chef-client runs once on boot only

# v4.4.3:
* workaround to make ec2 regions respect the cluster's region/AZ preference
* Making validation scope name prefix properly (fixes #201)

# v4.4.2:
* Support for intra-cluster ICMP and specs to prove it (thanks @nickmarden)
* Knife bash completion script: see config/knife.bash.README.md for installation (thanks @schade)

# v4.4.1:
* Re-enables integration specs, explicitly excluding them from "rake spec" (@nickmarden)

# v4.4.0: @nickmarden adds ELB support, broader spec coverage
* Security groups: removing ensured field (never set, causing bug), making selection use VPC if applicable
* Spec coverage for full cluster launch process
* IAMServerCertificate and ElasticLoadBalancer support for EC2
* Support for cluster-wide resource aggregation
* Fixes a bug that occurs when you fat-finger a flavor name

# v4.3.4:
* whoops. actually want attributes, not compact_attributes (#191)

# v4.3.3:
* Fixed "Terminated machines don't show up even with -VV" (#180)
* Removing superfluous old steps from cluster_launch
* Stringification of attributes and in_raid type

# v4.3.2:
* Adding cluster_name to cluster, to allow consistent semantics whether in cluster or facet

# v4.3.1:
* Correcting fullname to full_name for DSL::Compute children (this allows security_group(full_name) inside of facets)

# v4.3.0: VPC support
* Launch instances in pre-existing VPC and subnet, with group support
* Refactored security_group to handle VPC groups (which must use ID, not name)

# v4.2.3
* Making aws_account_id unnecessary for security groups (its not needed by newer Fog)
* Removed redundant cloud_provider.rb (thanks @nickmarden)
* Use Chef::Node-friendly semantics for chef_environment (thanks @nickmarden)

# v4.2.2: @mrflip rocks the house
* Terminated machines are not bogus (fixes #165)
* Ignore deleting, deleted, or errored volumes in discovery
* Rescue on duplicate security groups; don't die logging on full 'load!'
* Changed key_pair to keypair, as per the DSL
* Specs for scripts (but not really)
* Model cleanup -- now mostly round-trip to JSON
* knife cluster bootstrap sets Chef::Config[:environment] (fixes #148)

# v4.2.1: @nickmarden rocks the house
* Correct merging of cluster and facet objects, with specs (fixes #158)
* Circumvent memory bloat by resolving just once

# v4.2.0:
* providers now load in parallel
* substeps announcements for load are now done in provider, not individual resources
* only dump computers full information on -VV
* more cleanup of new specs

# v4.1.1: fixing 'rake spec'
* Remove all defunct tests and start fresh (fixes #137)
* Failing spec for #158

# v4.1.0: several bug-fixes and code cleanup
* Splat the args to DSL::Volume.snapshot_id so we can call it properly (fixes #161)
* cloud(:ec2) lets you declare bitness (fixes #147)
* Better logging; errors within Ironfan.parallel don't crash the world (pull #167)
* Like any good hitman, knife cluster kill should 'take care of' errant clients (pull #168)

# v4.0.9:
* Making bootstrap work again (fixes #159)

# v4.0.8:
* Removed .delegates_to, .parallelize in favor of manual delegation (via .each) and .parallel, to remove assumption that calls must be in the context of the individual object (preparation for fixing bootstrapping)
* Adding cluster and facet roles to server run list (fixes #160)
* Fixed blocking bugs in launch (bad versions 4.0.6 & 4.0.7)

# v4.0.5: security_group bug-fixes
* Fix for snapshot_id setting in cluster DSL
* Reinstated missing group_authorized capability

# v4.0.4: volume bug-fixes
* Made launch correctly create and tag secondary EBS volumes
* Adding some more warnings of code smells where separation of concerns has become blurry

# v4.0.3: volume bug-fixes
* Volume information should now be correctly saving to Chef nodes
* Keep flag now respected correctly for EBS root volumes

# v4.0.2: parallelize bug-fixes
* Added Ironfan.parallelize, to run the basic cluster commands in parallel against their servers
* Make security_group range and group authorizations store only unique values

# v4.0.1: volume bug-fixes
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

