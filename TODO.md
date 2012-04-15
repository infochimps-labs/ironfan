* We should use the `Fog::Compute::AWS::FLAVORS` constant that [fog defines](http://rubydoc.info/github/fog/fog/master/Fog/Compute/AWS) in the cloud code (instead of the one we put there)

* All over the place there is the following construct (absolutely necessary, absolutely horrid):

      foo = Mash.new().merge(node[:system]).merge(node[:system][:component])
      
  You might look at this and think "gee I know a much simpler way to do that". That simpler way does not work; this way does.

  I propose adding a 'smush' method to `silverware/libraries/cookbook_utils`: 
  
      ```ruby
      module Ironfan::CookbookUtils
        module_function
        
        # Merge the given objects (node attributes, hashes, or anything
        # else with `#to_hash`) into a combined `Mash` object. Objects 
        # given later in the list 'win' over objects given earlier.
        #
        # @examples
        #   template_vars = Ironfan::CookbookUtils.smush( node[:flume], node[:flume][:agent], :zookeeper_port => node[:zookeeper][:port] )
        #
        # @param [Array[#to_hash]] smushables -- any number of things that respond to `#to_hash`
        #
        def smush(*smushables)
          result = Mash.new
          smushables.compact.each do |smushable|
            result.merge! smushable.to_hash
          end
          result
        end
        
      end

  (obviously the hard part is not writing the method, it's applying it to all the cookbooks.)



### Knife commands

* knife cluster launch should fail differently if you give it a facet that doesn't exist


* reify notion of 'homebase'; cluster commands work off it
* move away from referring to Chef::Config everywhere; 


__________________________________________________________________________

Rename completed, 

New homes:

* **http://github.com/infochimps-labs/ironfan** -- the primary destination, and the home of the knife tools (pretty much what's here in `infochimps/cluster_chef`)
* **http://github.com/infochimps-labs/ironfan-pantry** -- collection of public cookbooks, roles and demo clusters
* **http://github.com/infochimps-labs/ironfan-homebase** -- skeleton homebase (looks a lot like the current cluster_chef-homebase)
* **http://github.com/infochimps-labs/ironfan-ci** -- continuous integration stuff (homebase/vagrants)
* **http://github.com/infochimps-labs/ironfan-scrubby** -- de-linter/simulator (`cluster_chef/lib/cluster_chef/cookbook_munger*`)
* **http://github.com/infochimps-labs/opscode-cookbooks** -- our fork of the opscode cookbooks repo

## Phase 1: Regex Replace

0. DONE warn about the name change. Since the `version_3` branch is left pre-namechange, decision was made to do a pull request when things are pull-able, not spam people before.
1. DONE Make a branch in each repo (`cluster_chef` and `*-homebase`) called `before_rename`, holding the current state of the code. Make another branch `ironfan`, where the renames will occur. That branch will be deleted as soon as the merge lands, hopefully before anyone even notices.
2. DONE Make sure `el_ridiculoso` is up to date and that it fully converges in the vagrant and cloud environments.
3. DONE Ensure all infochimps devs have push-pulled to various repos. make a tarball of the repos (.git and everything) and put them somewhere safe.
4. DONE rename the `vendor/infochimps/metachef` cookbook as vendor/infochimps/silverware. 
5. DONE Bump the *minor* version number on all cookbooks (so 3.0.x => 3.1.x). Commit.
6. DONE regex-replace `ClusterChef` => `Ironfan`, `cluster_chef` to `ironfan`  and `[Mm]etachef` => `[Ss]ilverware`. Do this in `cluster_chef` and `infochimps-labs/ironfan-homebase` only.  Get chef-client to complete on el_ridiculoso using an emptied-and-reloaded local chef server. Run knife cluster sync on all clusters in all homebases against local chef server.
7. ...
12. DONE once the name is updated in the gemspec, release the `ironfan` gem. @temujin9 and I agree that it should be a single combined gem now that we won't have the stupid `_chef` gem name conflict.

## Phase 2: Repo migration

1. DONE back up the repo and put it somewhere safe.
2. DONE Transfer ownership of `infochimps/cluster_chef` to `infochimps-labs/cluster_chef`. Do whatever is necessary/possible to migrate issues over.
3. DONE Change name of `infochimps-labs/cluster_chef` to `infochimps-labs/ironfan`. Created new repo `infochimps-labs/ironfan-homebase`. 4. DONE Create new repo `infochimps/cluster_chef` with helpful link to new repo. I don't think we need a placeholder at `infochimps-labs/cluster_chef-homebase`.
5. DONE Rename master branch of old cluster chef to be `version_2`, and freeze the `version_3`. Both now carry a deprecation warning pointing you to ironfan. 
6. IN PROGRESS Update any remaining documentation links, etc to point to new home.
7. IN PROGRESS Have all devs edit their .git/config to point at right place.

so here is the dev-level worksforme -- @temujin9 will close once he's given it the sysadmin-level worksforme






# Old Issues Triage
From https://github.com/infochimps-labs/ironfan/issues/102 with love. Deleted ownership, and everything that was done or has its own issue.

## Must Do
* merge volumes into silverware. merge ebs_volumes into ec2 cookbook 
* Basic CI testing of cookbooks 
* RSpecs for silverback (lib and knife tools) 
* RSpecs for silverware are mostly in place -- ensure they are. 
* push cookbooks to community.opscode.com  
* refine and explain updated git workflow

## Docco
Use the [opscode EC2 fast start](http://wiki.opscode.com/display/chef/EC2+Bootstrap+Fast+Start+Guide) as a guide -- our getting started should start at the same place, and cover the same detail as the EC2 bootstrap guide.

* Clear description of metadiscovery
* make sure README files in cookbooks aren’t wildly inaccurate
* Carry out setup directions, ensure they work:
  - cluster_chef if you’re using our homebase
  - cluster_chef if you’re using opscode’s homebase
* local vagrant environment 
* hadoop cluster bootstrapping

## Piddly Shit

* standardize the `zabbix` cookbook (no more /opt, etc -- more in the TODO)
* volumes don't deep merge -- eg you have to mount_ephemerals in the facet if you modify htem
* kill_old_service should disable services (may be leaving /etc/rc.d cruft).
* kill old service doesn't go the first time. why?
* chef client/server cookbook: set chef user UID / GID; client can set log directory
* apt has a dashboard at http://{hostname}:3142/report
* can use knife ssh as me@ or as ubuntu@
* knife command to set/remove permanent on a node + disableApiTermination on box. knife cluster kill refuses to delete nodes with permanent set. knife cluster sync sets permanent on if permanent(true), removes if permanent(false), ignores if permanent nil or unset. 
* style-guide alignment (prefix_root becomes prefix)

## Really Want

* unify the hashlike underpinning to be same across silverware & cluster_chef. Make sure we love (or accept) all the differences between it and Gorrillib’s, and between it and Chef’s.
* Keys are transmitted in databags, using a helper, and not in node attributes
* easy to create a dummy node (load balancer, external resource, etc)
* components can have arbitrary attributes (kinda. they take an `:info` param, behavior which may change later)
* All cookbooks have nice detailed announcements
* full roll out of log_integration, monitoring
* Git deploy abstraction similar to `install_from` 

## Cookbook checklist:
* Validate all the cookbooks against checklist -- see notes/README-checklist.md 

                          | flip fixed | temujin9 checked |
                          +------------+------------------+
        cassandra         |            |                  |
        ec2               |            |                  |
        elasticsearch     |            |                  |
        firewall          |            |                  |
        flume             |            |                  |
        ganglia           |            |                  |
        graphite          |            |                  |
        hadoop_cluster    |            |                  |
        hbase             |            |                  |
        hive              |            |                  |
        jenkins           |            |                  |
        jruby             |            |                  |
        nfs               |            |                  |
        nodejs            |            |                  |
        papertrail        |            |                  |
        pig               |            |                  |
        redis             |            |                  |
        resque            |            |                  |
        Rstats            |            |                  |
        statsd            |            |                  |
        zookeeper         |            |                  |
        # meta:
        install_from      |            |                  |
        motd              |            |                  |
        mountable_volumes |            |                  |
        provides_service  |            |                  |
        # Need thinkin':
        big_package       |            |                  |
        cluster_chef      |            |                  |


## Things that are probably straightforward to fix as soon as we know how

* announcements should probably be published very early, but they need to know lots about the machine YUK
* split between clusters / roles / integration cookbooks
* inheritance of clusters

## Things We Hate But Might Have to Continue Hating

* Cluster refactor -- clusters / stacks / components, not clusters / roles / cookbooks
* move cluster discovery to cloud class.
* Server#normalize! doesn’t imprint object (ie. server attributes poke through to the facet & cluster, rather than being *set* on the object)
* The fact you can only see one cluster at a time is stupid.
* security group pairing is sucky.
* ubuntu home drive bullshit
* Finer-grained security group control (eg nfs server only opens a couple ports, not all)
* nfs recipe uses discovery right (thus allowing more than one NFS share to exist in the universe)
* roles UGGGHHHHAERWSDFKHSBLAH

## Ponies!
* sync cookbooks up/down to `infochimps-cookbooks/` 
  - note: infochimps-cookbooks the org will be dereferenced in favor of ironfan-lib the single repo; it's unclear which pull requesters will prefer. We will do at least one push so that names and URLs are current, and we're not removing anything, but infochimps-cookbooks has an unclear future.
* foodcritic compatibility
* build out cookbook munger, make it less spike-y
* spot pricing
* rackspace compatibility
* cookbook munger reads comments in attributes file to populate metadata.rb
* `gem install ironfan; ironfan install` checks everything out
