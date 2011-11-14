maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures cluster_chef"



%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "server_tuning/ulimit/default",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "server_tuning/ulimit/@elasticsearch",
  :type                  => "hash",
  :default               => {:nofile=>{:both=>32768}, :nproc=>{:both=>50000}},
  :display_name          => "",
  :description           => ""
