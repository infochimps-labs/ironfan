## v3.0.6: schism of cookbooks and tools

* cookbooks all now live in [their own repo](https://github.com/infochimps-labs/cluster_chef-homebase), organized according to opscode standard.
* gem is now split into `cluster_chef` (the libraries) and `cluster_chef-knife` (the chef plugins)
* private_key was passing its block to super, with bad results

## Changes from v2 => v3 [2011 October]

**The below-described changes are still in progress**

_________

ClusterChef underwent a major upgrade with the last several commits.

* the `cluster_chef` tools -- the DSL, knife plugins, and bootstrap scripts -- have been split out of the  [cluster_chef repo](http://github.com/infochimps/cluster_chef) into a [separate repo](http://github.com/infochimps/cluster_chef-tools).
* The tools are now available as a gem -- `gem install cluster_chef`
* Cleaned up the code
* Standardized clusters & roles
* Standardized cookbooks

### ClusterChef DSL Changes

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

* Standardized on `node[:cluster_name]`, `node[:facet_name]` and `node[:facet_index]` as the way to refer to the cluster, facet and server parts of a node's name. This replaces the way-too-many names for these: `node[:cluster_chef][:facet]` and `node[:cluster_role]` (use `node[:facet_name]`), `node[:cluster_chef][:index]` and `node[:cluster_role_index]` (use `node[:facet_index]`) .
* ClusterChef family of cookbooks were updated accordingly.

#### hadoop_cluster cookbook

* The bootstrap recipes are gone. They may come back, but for now the dance is:
  - bring up the cluster ; by default the service state for all the daemons is [:disable, :stop].
  - run the `/etc/hadoop/conf/bootstrap_hadoop_namenode.sh` to format your HDFS
  - move the service state to '[:enable, :start]' and re-run chef client
  

#### Deprecated cookbooks

You must add `"#{cluster_chef_path}/deprecated-cookbooks"` to your cookbook_path in knife.rb if you would like to keep using

* `cluster_ebs_volumes` -- use `mountable_volumes` instead.

