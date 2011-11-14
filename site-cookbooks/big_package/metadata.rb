# http://wiki.opscode.com/display/chef/Metadata
maintainer        "Infochimps.org"
maintainer_email  "help@infochimps.org"
license           "Apache 2.0"
description       "A bunch of fun packages"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.2.0"

%w{ debian ubuntu }.each do |os|
  supports os
end
