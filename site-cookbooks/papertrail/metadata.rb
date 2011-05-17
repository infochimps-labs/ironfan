maintainer       "Librato, Inc."
maintainer_email "mike@librato.com"
license          "All rights reserved"
description      "Installs/Configures Sys Logging to papertrailapp.com"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.1"

depends          "rsyslog"

# TODO: test on fedora
%w{ubuntu}.each do |os|
  supports os
end
