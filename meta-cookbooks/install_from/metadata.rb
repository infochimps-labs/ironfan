maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures install_from"


recipe           "install_from::default",              "Base configuration for install_from"

%w[ debian ubuntu ].each do |os|
  supports os
end
