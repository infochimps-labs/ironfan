= DESCRIPTION:

Cookbook to connect syslogging to papertrailapp.com.

= REQUIREMENTS:

 * rsyslog cookbook

= ATTRIBUTES:

node[:papertrail][:logger] - Logger to use. Support loggers include: rsyslog. Defaults to rsyslog.

node[:papertrail][:remote_host] - Papertrail host to send stats to. Defaults to 'logs.papertrailapp.com'.

node[:papertrail][:remote_port] - Port to use. No default.

node[:papertrail][:cert_file] - Where to store papertrail cert file..

node[:papertrail][:cert_url] - URL to download certificate from.

By default, this recipe will log to Papertrail using the system's
hostname. If you want to set the hostname that will be used (think
ephemeral cloud nodes) you can set one of the following. If either is
set it will use the hostname_name first and the hostname_cmd second.

node[:papertrail][:hostname_name] - Set the logging hostname to this string.

node[:papertrail][:hostname_cmd] - Set the logging hostname to the
output of this command passed to system(). This is useful if the
desired hostname comes from a dynamic source like EC2 meta-data.

File monitoring is not really a part of papertrail but is included here:

node[:papertrail][:watch_files] - This is a list of files that will be
configured to be watched and included in the papertrail logging. This
is useful for including output from applications that aren't
configured to use syslog. Each entry in this list is a hash of:

           [:filename] - Full path to the file.
           [:tag] - What to tag log lines that come from this file. Best to
                    use a short application name.

= USAGE:

Just include the default recipe.
