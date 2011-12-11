maintainer       "Benjamin Black"
maintainer_email "b@b3k.us"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "Redis: a fast, flexible datastore offering an extremely useful set of data structure primitives"

depends          "runit"
depends          "install_from"
depends          "metachef"

recipe           "redis::default",                     "Base configuration for redis"
recipe           "redis::install_from_package",        "Install From Ubuntu Package -- easy but lags in version"
recipe           "redis::install_from_release",        "Install From Release"
recipe           "redis::server",                      "Redis server with runit service"
recipe           "redis::client",                      "Client support for Redis database"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "redis/home_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/local/share/redis"

attribute "redis/pid_file",
  :display_name          => "Redis PID file path",
  :description           => "Path to the PID file when daemonized.",
  :default               => "/var/run/redis.pid"

attribute "redis/log_file",
  :display_name          => "Redis log file path",
  :description           => "Path to the log file when daemonized.",
  :default               => "/var/log/redis/redis.log"

attribute "redis/data_dir",
  :display_name          => "Redis database directory",
  :description           => "Path to the directory for database files.",
  :default               => "/var/lib/redis"

attribute "redis/db_basename",
  :display_name          => "Redis database filename",
  :description           => "Filename for the database storage.",
  :default               => "dump.rdb"

attribute "redis/release_url",
  :display_name          => "URL for redis release package",
  :description           => "If using the install_from_release strategy, the URL for the release tarball",
  :default               => "http://redis.googlecode.com/files/redis-:version:.tar.gz"

attribute "redis/master_server",
  :display_name          => "Redis replication master server name",
  :description           => "The master server for this replication slave.",
  :default               => "master-redis.domain"

attribute "redis/master_port",
  :display_name          => "Redis replication master server port",
  :description           => "The master server port for this replication slave.",
  :default               => "6379"

attribute "redis/glueoutputbuf",
  :display_name          => "Redis output buffer coalescing",
  :description           => "Glue small output buffers together into larger TCP packets.",
  :default               => "yes"

attribute "redis/saves",
  :display_name          => "Redis disk persistence policies",
  :description           => "An array of arrays of time, changed objects policies for persisting data to disk.",
  :type                  => "array",
  :default               => [["900", "1"], ["300", "10"], ["60", "10000"]]

attribute "redis/slave",
  :display_name          => "Redis replication slave",
  :description           => "Act as a replication slave to a master redis database.",
  :default               => "no"

attribute "redis/shareobjects",
  :display_name          => "Redis shared object compression (default: \"no\")",
  :description           => "Attempt to reduce memory use by sharing storage for substrings.",
  :default               => "no"

attribute "redis/shareobjectspoolsize",
  :display_name          => "Redis shared object pool size",
  :description           => "The size of the pool for object sharing.",
  :default               => "1024"

attribute "redis/conf_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/etc/redis"

attribute "redis/log_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/var/log/redis"

attribute "redis/user",
  :display_name          => "",
  :description           => "",
  :default               => "redis"

attribute "redis/version",
  :display_name          => "",
  :description           => "",
  :default               => "2.0.2"

attribute "redis/server/addr",
  :display_name          => "IP address to bind.",
  :description           => "IP address to bind.",
  :default               => "0.0.0.0"

attribute "redis/server/port",
  :display_name          => "Redis server port",
  :description           => "TCP port to bind.",
  :default               => "6379"

attribute "redis/server/timeout",
  :display_name          => "Redis server timeout",
  :description           => "Timeout, in seconds, for disconnection of idle clients.",
  :default               => "300"

attribute "users/redis/uid",
  :display_name          => "",
  :description           => "",
  :default               => "335"

attribute "groups/redis/gid",
  :display_name          => "",
  :description           => "",
  :default               => "335"
