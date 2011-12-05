maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "Installs/Configures resque"

depends          "runit"
depends          "redis"

recipe           "resque::default",                    "Base configuration for resque"
recipe           "resque::server",                     "Server"
recipe           "resque::dedicated_redis",            "Dedicated redis -- a redis solely for this resque"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "resque/dir",
  :display_name          => "",
  :description           => "",
  :default               => "/data/db/resque"

attribute "resque/log_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/var/log/resque"

attribute "resque/tmp_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/data/db/resque/tmp"

attribute "resque/data_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/data/db/resque/data"

attribute "resque/journal_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/data/db/resque/swap"

attribute "resque/conf_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/etc/resque"

attribute "resque/db_basename",
  :display_name          => "",
  :description           => "",
  :default               => "resque_queue.rdb"

attribute "resque/cluster_name",
  :display_name          => "",
  :description           => "",
  :default               => "cluster_name"

attribute "resque/namespace",
  :display_name          => "",
  :description           => "",
  :default               => "cluster_name"

attribute "resque/user",
  :display_name          => "",
  :description           => "",
  :default               => "resque"

attribute "resque/group",
  :display_name          => "",
  :description           => "",
  :default               => "resque"

attribute "resque/queue_addr",
  :display_name          => "",
  :description           => "",
  :default               => "10.20.30.40"

attribute "resque/queue_port",
  :display_name          => "",
  :description           => "",
  :default               => "6388"

attribute "resque/dashboard_port",
  :display_name          => "",
  :description           => "",
  :default               => "6389"

attribute "resque/redis_client_timeout",
  :display_name          => "",
  :description           => "",
  :default               => "300"

attribute "resque/redis_glueoutputbuf",
  :display_name          => "",
  :description           => "",
  :default               => "yes"

attribute "resque/redis_vm_enabled",
  :display_name          => "",
  :description           => "",
  :default               => "yes"

attribute "resque/redis_vm_max_memory",
  :display_name          => "",
  :description           => "",
  :default               => "128m"

attribute "resque/redis_vm_pages",
  :display_name          => "",
  :description           => "",
  :default               => "16777216"

attribute "resque/redis_saves",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => [["900", "1"], ["300", "10"], ["60", "10000"]]

attribute "resque/redis_slave",
  :display_name          => "",
  :description           => "",
  :default               => "no"

attribute "resque/app_env",
  :display_name          => "",
  :description           => "",
  :default               => "production"

attribute "resque/home_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/data/db/resque"

attribute "resque/pid_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/var/run/resque"

attribute "resque/redis/run_state",
  :display_name          => "",
  :description           => "",
  :default               => "start"

attribute "resque/redis/server/addr",
  :display_name          => "",
  :description           => "",
  :default               => "0.0.0.0"

attribute "resque/redis/server/port",
  :display_name          => "",
  :description           => "",
  :default               => "6388"

attribute "resque/dashboard/port",
  :display_name          => "",
  :description           => "",
  :default               => "6389"

attribute "resque/dashboard/run_state",
  :display_name          => "",
  :description           => "",
  :default               => "start"

attribute "users/resque/uid",
  :display_name          => "",
  :description           => "",
  :default               => "336"

attribute "groups/resque/gid",
  :display_name          => "",
  :description           => "",
  :default               => "336"
