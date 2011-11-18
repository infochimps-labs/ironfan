maintainer       "Fletcher Nichol"
maintainer_email "fnichol@nichol.ca"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.5"

description      "Installs and configures Jenkins CI server & slaves"

depends          "java"
depends          "apache2"
depends          "nginx"
depends          "runit"
depends          "iptables"
depends          "mountable_volumes"
depends          "provides_service"

recipe           "jenkins::auth_github_oauth",         "Auth Github Oauth"
recipe           "jenkins::build_from_github",         "Build From Github"
recipe           "jenkins::build_ruby_rspec",          "Build Ruby Rspec"
recipe           "jenkins::default",                   "Installs a Jenkins CI server using the http://jenkins-ci.org/redhat RPM.  The recipe also generates an ssh private key and stores the ssh public key in the node 'jenkins[:pubkey]' attribute for use by the node recipes."
recipe           "jenkins::iptables",                  "Set up ip_tables to allow access to the daemons"
recipe           "jenkins::node_jnlp",                 "Creates the user and group for the Jenkins slave to run as and '/jnlpJars/slave.jar' is downloaded from the Jenkins server.  Depends on runit_service from the runit cookbook."
recipe           "jenkins::node_ssh",                  "Creates the user and group for the Jenkins slave to run as and sets `.ssh/authorized_keys` to the 'jenkins[:pubkey]' attribute.  The 'jenkins-cli.jar'[1] is downloaded from the Jenkins server and used to manage the nodes via the 'groovy'[2] cli command.  Jenkins is configured to launch a slave agent on the node using its SSH slave plugin[3].\n\n[1] http://wiki.jenkins-ci.org/display/JENKINS/Jenkins+CLI\n[2] http://wiki.jenkins-ci.org/display/JENKINS/Jenkins+Script+Console\n[3] http://wiki.jenkins-ci.org/display/JENKINS/SSH+Slaves+plugin"
recipe           "jenkins::node_windows",              "Creates the home directory for the node slave and sets 'JENKINS_HOME' and 'JENKINS_URL' system environment variables.  The 'winsw'[1] Windows service wrapper will be downloaded and installed, along with generating `jenkins-slave.xml` from a template.  Jenkins is configured with the node as a 'jnlp'[2] slave and '/jnlpJars/slave.jar' is downloaded from the Jenkins server.  The 'jenkinsslave' service will be started the first time the recipe is run or if the service is not running.  The 'jenkinsslave' service will be restarted if '/jnlpJars/slave.jar' has changed.  The end results is functionally the same had you chosen the option to 'Let Jenkins control this slave as a Windows service'[3].\n\n[1] http://weblogs.java.net/blog/2008/09/29/winsw-windows-service-wrapper-less-restrictive-license\n[2] http://wiki.jenkins-ci.org/display/JENKINS/Distributed+builds\n[3] http://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+as+a+Windows+service"
recipe           "jenkins::proxy_apache2",             "Uses the apache2 recipe from the apache2 cookbook to install an HTTP frontend proxy. To automatically activate this recipe set the `node[:jenkins][:http_proxy][:variant]` to `apache2`."
recipe           "jenkins::proxy_nginx",               "Uses the nginx::source recipe from the nginx cookbook to install an HTTP frontend proxy. To automatically activate this recipe set the `node[:jenkins][:http_proxy][:variant]` to `nginx`."
recipe           "jenkins::server",                    "Server"
recipe           "jenkins::user_key",                  "User Key"
recipe           "jenkins::cli",                       "This resource can be used to execute the Jenkins cli from your recipes.  For example, install plugins via update center and restart Jenkins:\n\n    %w(git URLSCM build-publisher).each do |plugin|\n      jenkins_cli \"install-plugin \#{plugin}\"\n      jenkins_cli \"safe-restart\"\n    end"
recipe           "jenkins::node",                      "This resource can be used to configure nodes as the 'node_ssh' and 'node_windows' recipes do or \"Launch slave via execution of command on the Master\"\n\n    jenkins_node node[:fqdn] do\n      description  \"My node for things, stuff and whatnot\"\n      executors    5\n      remote_fs    \"/var/jenkins\"\n      launcher     \"command\"\n      command      \"ssh -i my_key \#{node[:fqdn]} java -jar \#{remote_fs}/slave.jar\"\n      env          \"ANT_HOME\" => \"/usr/local/ant\", \"M2_REPO\" => \"/dev/null\"\n    end"
recipe           "jenkins::job",                       "This resource manages jenkins jobs, supporting the following actions:\n\n   :create, :update, :delete, :build, :disable, :enable\n\nThe 'create' and 'update' actions require a jenkins job config.xml.  Example:\n\n    git_branch = 'master'\n    job_name = \"sigar-\#{branch}-\#{node[:os]}-\#{node[:kernel][:machine]}\"\n\n    job_config = File.join(node[:jenkins][:node][:home], \"\#{job_name}-config.xml\")\n\n    jenkins_job job_name do\n      action :nothing\n      config job_config\n    end\n\n    template job_config do\n      source \"sigar-jenkins-config.xml\"\n      variables :job_name => job_name, :branch => git_branch, :node => node[:fqdn]\n      notifies :update, resources(:jenkins_job => job_name), :immediately\n      notifies :build, resources(:jenkins_job => job_name), :immediately\n    end"
recipe           "jenkins::manage_node",               "The script to generate groovy that manages a node can be used standalone.  For example:\n\n    % ruby manage_node.rb name slave-hostname remote_fs /home/jenkins ... | java -jar jenkins-cli.jar -s http://jenkins:8080/ groovy = "

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "apt/jenkins/url",
  :display_name          => "URL of apt repo for downloading Jenkins (server)",
  :description           => "URL of apt repo for downloading Jenkins (server)",
  :default               => "http://pkg.jenkins-ci.org/debian"

attribute "jenkins/plugins_mirror",
  :display_name          => "",
  :description           => "",
  :default               => "http://updates.jenkins-ci.org"

attribute "jenkins/java_home",
  :display_name          => "Java install path, used for for cli commands",
  :description           => "Java install path, used for for cli commands",
  :default               => "/System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Home"

attribute "jenkins/iptables_allow",
  :display_name          => "if iptables is enabled, add a rule passing 'jenkins[:server][:port]'",
  :description           => "if iptables is enabled, add a rule passing 'jenkins[:server][:port]'",
  :default               => "enable"

attribute "jenkins/server/home",
  :display_name          => "JENKINS_HOME directory",
  :description           => "JENKINS_HOME directory",
  :default               => "/var/lib/jenkins"

attribute "jenkins/server/user",
  :display_name          => "User the Jenkins server runs as",
  :description           => "User the Jenkins server runs as",
  :default               => "jenkins"

attribute "jenkins/server/group",
  :display_name          => "",
  :description           => "Jenkins user primary group",
  :default               => "nogroup"

attribute "jenkins/server/port",
  :display_name          => "TCP listen port for the Jenkins server",
  :description           => "TCP listen port for the Jenkins server",
  :default               => "8080"

attribute "jenkins/server/host",
  :display_name          => "Host interface address for the Jenkins server",
  :description           => "Host interface address for the Jenkins server",
  :default               => ""

attribute "jenkins/server/jvm_heap",
  :display_name          => "tunable: Java maximum heap size",
  :description           => "tunable: Java maximum heap size",
  :default               => "384"

attribute "jenkins/server/plugins",
  :display_name          => "Download the latest version of plugins in this list, bypassing update center",
  :description           => "Download the latest version of plugins in this list, bypassing update center",
  :default               => ""

attribute "jenkins/server/use_head",
  :display_name          => "working around: http://tickets.opscode.com/browse/CHEF-1848; set to true if you have the CHEF-1848 patch applied",
  :description           => "working around: http://tickets.opscode.com/browse/CHEF-1848; set to true if you have the CHEF-1848 patch applied",
  :default               => ""

attribute "jenkins/node/name",
  :display_name          => "Name of the node within Jenkins",
  :description           => "Name of the node within Jenkins",
  :default               => ""

attribute "jenkins/node/description",
  :display_name          => "Jenkins node description",
  :description           => "Jenkins node description",
  :default               => "ubuntu 10.4 [  ] slave on hostname"

attribute "jenkins/node/executors",
  :display_name          => "Number of node executors",
  :description           => "Number of node executors",
  :default               => "1"

attribute "jenkins/node/home",
  :display_name          => "Home directory (`Remote FS root`) of the node",
  :description           => "Home directory (`Remote FS root`) of the node",
  :default               => "/var/lib/jenkins-node"

attribute "jenkins/node/labels",
  :display_name          => "Node labels",
  :description           => "Node labels",
  :default               => ""

attribute "jenkins/node/mode",
  :display_name          => "Node usage mode, `normal` or `exclusive` (tied jobs only)",
  :description           => "Node usage mode, `normal` or `exclusive` (tied jobs only)",
  :default               => "normal"

attribute "jenkins/node/launcher",
  :display_name          => "Node launch method: `jnlp`, `ssh` or `command`",
  :description           => "Node launch method: `jnlp`, `ssh` or `command`",
  :default               => "ssh"

attribute "jenkins/node/availability",
  :display_name          => "`always` keeps node on-line, `demand` off-lines when idle",
  :description           => "`always` keeps node on-line, `demand` off-lines when idle",
  :default               => "always"

attribute "jenkins/node/in_demand_delay",
  :display_name          => "number of minutes for which jobs must be waiting in the queue before attempting to launch this slave.",
  :description           => "number of minutes for which jobs must be waiting in the queue before attempting to launch this slave.",
  :default               => "0"

attribute "jenkins/node/idle_delay",
  :display_name          => "number of minutes that this slave must remain idle before taking it off-line. ",
  :description           => "number of minutes that this slave must remain idle before taking it off-line. ",
  :default               => "1"

attribute "jenkins/node/env",
  :display_name          => "`Node Properties` -> `Environment Variables`",
  :description           => "`Node Properties` -> `Environment Variables`",
  :default               => ""

attribute "jenkins/node/user",
  :display_name          => "user the slave runs as",
  :description           => "user the slave runs as",
  :default               => "jenkins-node"

attribute "jenkins/node/ssh_host",
  :display_name          => "Hostname or IP Jenkins should connect to when launching an SSH slave",
  :description           => "Hostname or IP Jenkins should connect to when launching an SSH slave",
  :default               => ""

attribute "jenkins/node/ssh_port",
  :display_name          => "SSH slave port",
  :description           => "SSH slave port",
  :default               => "22"

attribute "jenkins/node/ssh_user",
  :display_name          => "SSH slave user name (only required if jenkins server and slave user is different)",
  :description           => "SSH slave user name (only required if jenkins server and slave user is different)",
  :default               => "22"

attribute "jenkins/node/ssh_pass",
  :display_name          => "SSH slave password (not required when server is installed via default recipe)",
  :description           => "SSH slave password (not required when server is installed via default recipe)",
  :default               => ""

attribute "jenkins/node/jvm_options",
  :display_name          => "SSH slave JVM options",
  :description           => "SSH slave JVM options",
  :default               => ""

attribute "jenkins/node/ssh_private_key",
  :display_name          => "jenkins master defaults to: `~/.ssh/id_rsa` (created by the default recipe)",
  :description           => "jenkins master defaults to: `~/.ssh/id_rsa` (created by the default recipe)",
  :default               => ""

attribute "jenkins/http_proxy/variant",
  :display_name          => "use `nginx` or `apache2` to proxy traffic to jenkins backend (`nil` by default)",
  :description           => "use `nginx` or `apache2` to proxy traffic to jenkins backend (`nil` by default)",
  :default               => ""

attribute "jenkins/http_proxy/www_redirect",
  :display_name          => "add a redirect rule for 'www.*' URL requests (\"disable\" by default)",
  :description           => "add a redirect rule for 'www.*' URL requests (\"disable\" by default)",
  :default               => "disable"

attribute "jenkins/http_proxy/listen_ports",
  :display_name          => "list of HTTP ports for the HTTP proxy to listen on ([80] by default)",
  :description           => "list of HTTP ports for the HTTP proxy to listen on ([80] by default)",
  :type                  => "array",
  :default               => [80]

attribute "jenkins/http_proxy/host_name",
  :display_name          => "primary vhost name for the HTTP proxy to respond to (`node[:fqdn]` by default)",
  :description           => "primary vhost name for the HTTP proxy to respond to (`node[:fqdn]` by default)",
  :default               => ""

attribute "jenkins/http_proxy/host_aliases",
  :display_name          => "optional list of other host aliases to respond to (empty by default)",
  :description           => "optional list of other host aliases to respond to (empty by default)",
  :default               => ""

attribute "jenkins/http_proxy/client_max_body_size",
  :display_name          => "max client upload size (`1024m` by default, nginx only)",
  :description           => "max client upload size (`1024m` by default, nginx only)",
  :default               => "1024m"
