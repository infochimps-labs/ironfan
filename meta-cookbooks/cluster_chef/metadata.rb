maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures cluster_chef"


recipe           "cluster_chef::burn_ami_prep",        "Burn Ami Prep"
recipe           "cluster_chef::cluster_webfront",     "Cluster Webfront"
recipe           "cluster_chef::dedicated_server_tuning", "Dedicated Server Tuning"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "server_tuning/ulimit/default",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "server_tuning/ulimit/@elasticsearch",
  :display_name          => "",
  :description           => "",
  :type                  => "hash",
  :default               => {:nofile=>{:both=>32768}, :nproc=>{:both=>50000}}
