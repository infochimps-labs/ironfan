= DESCRIPTION:

Installs and configures Jenkins CI server & node slaves.  Resource providers to support automation via jenkins-cli, including job create/update.

### Notes

#### Compatibility:
 
* 'default' - Server installation - currently supports Red Hat/CentOS 5.x and Ubuntu 8.x/9.x/10.x
* 'node_ssh' - Any platform that is running sshd.
* 'node_jnlp' - Unix platforms. (depends on runit recipe)
* 'node_windows' - Windows platforms only.  Depends on .NET Framework, which can be installed with the windows::dotnetfx recipe.

#### Jenkins node authentication:

If your Jenkins instance requires authentication, you'll either need to embed user:pass in the jenkins.server.url or issue a jenkins-cli.jar login command prior to using the jenkins::node_* recipes.  For example, define a role like so:

  name "jenkins_ssh_node"
  description "cli login & register ssh slave with Jenkins"
  run_list %w(vmw::jenkins_login jenkins::node_ssh)

Where the jenkins_login recipe is simply:

  jenkins_cli "login --username #{node[:jenkins][:username]} --password #{node[:jenkins][:password]}"


#### ISSUES

* CLI authentication - http://issues.jenkins-ci.org/browse/JENKINS-3796

* CLI *-node commands fail with "No argument is allowed: nameofslave" - http://issues.jenkins-ci.org/browse/JENKINS-5973

#### LICENSE & AUTHOR:

This is a downstream fork of Doug MacEachern's Hudson cookbook (https://github.com/dougm/site-cookbooks) and therefore deserves all the glory.

Author:: Doug MacEachern (<dougm@vmware.com>)

Contributor:: Fletcher Nichol <fnichol@nichol.ca>
Contributor:: Roman Kamyk <rkj@go2.pl>
Contributor:: Darko Fabijan <darko@renderedtext.com>
