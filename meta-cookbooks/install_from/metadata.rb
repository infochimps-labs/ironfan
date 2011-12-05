maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "Installs/Configures install_from"


recipe           "install_from::default",              "Base configuration for install_from"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "install_from/apache_mirror",
  :display_name          => "Default Apache mirror to use",
  :description           => "Choose one of the [Apache project mirrors](http://www.apache.org/dyn/closer.cgi) -- omit the trailing '/'s. The token `:apache_mirror:` (note : at end of token) in a `release_url` attribute will be replaced by this base; see the pig recipe for an example.",
  :default               => "http://apache.mirrors.tds.net"
