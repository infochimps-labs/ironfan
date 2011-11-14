maintainer       "Mike Heffner, Librato, Inc."
maintainer_email "mike@librato.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures Sys Logging to papertrailapp.com"

depends          "rsyslog"


%w[ debian ubuntu ].each do |os|
  supports os
end
