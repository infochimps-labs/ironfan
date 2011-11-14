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

attribute "papertrail/logger",
  :default               => "rsyslog",
  :display_name          => "",
  :description           => ""

attribute "papertrail/remote_host",
  :default               => "logs.papertrailapp.com",
  :display_name          => "",
  :description           => ""

attribute "papertrail/remote_port",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "papertrail/cert_file",
  :default               => "/etc/papertrail.crt",
  :display_name          => "",
  :description           => ""

attribute "papertrail/cert_url",
  :default               => "https://papertrailapp.com/tools/syslog.papertrail.crt",
  :display_name          => "",
  :description           => ""

attribute "papertrail/hostname_name",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "papertrail/hostname_cmd",
  :display_name          => "",
  :description           => "",
  :default               => ""
