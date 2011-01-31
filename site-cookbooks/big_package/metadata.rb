# http://wiki.opscode.com/display/chef/Metadata
maintainer        "Infochimps.org"
maintainer_email  "help@infochimps.org"
license           "Apache 2.0"
description       "A bunch of fun packages"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version           "0.0.1"

%w{ debian ubuntu }.each do |os|
  supports os
end
