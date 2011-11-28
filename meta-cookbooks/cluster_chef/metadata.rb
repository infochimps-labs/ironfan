maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures cluster_chef"

depends          'runit'

recipe           "cluster_chef::burn_ami_prep",           "Burn Ami Prep"
recipe           "cluster_chef::dashboard",               "Lightweight dashboard for this machine: index of services and their dashboard snippets"
recipe           "cluster_chef::dedicated_server_tuning", "Dedicated Server Tuning"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "server_tuning/ulimit",
  :display_name          => "",
  :description           => "",
  :default               => ""
