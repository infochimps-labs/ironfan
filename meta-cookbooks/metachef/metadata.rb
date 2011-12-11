maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "Cluster orchestration -- coordinates discovery, integration and decoupling of cookbooks"

recipe           "metachef::default",              "Base configuration for metachef"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "metachef/conf_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/etc/metachef"

attribute "metachef/log_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/var/log/metachef"

attribute "metachef/home_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/etc/metachef"

attribute "metachef/user",
  :display_name          => "",
  :description           => "",
  :default               => "root"

attribute "users/root/primary_group",
  :display_name          => "",
  :description           => "",
  :default               => "root"
