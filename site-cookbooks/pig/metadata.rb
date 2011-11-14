maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures pig"

depends          "hadoop_cluster"
depends          "install_from"


%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "pig/home_dir",
  :display_name          => nil,
  :description           => nil
