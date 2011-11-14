maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures resque"

depends          "runit"
depends          "redis"


%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "resque/dir",
  :default               => "/data/db/resque",
  :display_name          => "",
  :description           => ""

attribute "resque/log_dir",
  :default               => "/data/db/resque/log",
  :display_name          => "",
  :description           => ""

attribute "resque/tmp_dir",
  :default               => "/data/db/resque/tmp",
  :display_name          => "",
  :description           => ""

attribute "resque/dbdir",
  :default               => "/data/db/resque/data",
  :display_name          => "",
  :description           => ""

attribute "resque/swapdir",
  :default               => "/data/db/resque/swap",
  :display_name          => "",
  :description           => ""

attribute "resque/conf_dir",
  :default               => "/etc/resque",
  :display_name          => "",
  :description           => ""

attribute "resque/dbfile",
  :default               => "resque_queue.rdb",
  :display_name          => "",
  :description           => ""

attribute "resque/cluster_name",
  :default               => "cluster_name",
  :display_name          => "",
  :description           => ""

attribute "resque/namespace",
  :default               => "cluster_name",
  :display_name          => "",
  :description           => ""

attribute "resque/user",
  :default               => "resque",
  :display_name          => "",
  :description           => ""

attribute "resque/group",
  :default               => "resque",
  :display_name          => "",
  :description           => ""

attribute "resque/queue_address",
  :default               => "10.20.30.40",
  :display_name          => "",
  :description           => ""

attribute "resque/queue_port",
  :default               => "6388",
  :display_name          => "",
  :description           => ""

attribute "resque/dashboard_port",
  :default               => "6389",
  :display_name          => "",
  :description           => ""

attribute "resque/redis_client_timeout",
  :default               => "300",
  :display_name          => "",
  :description           => ""

attribute "resque/redis_glueoutputbuf",
  :default               => "yes",
  :display_name          => "",
  :description           => ""

attribute "resque/redis_vm_enabled",
  :default               => "yes",
  :display_name          => "",
  :description           => ""

attribute "resque/redis_vm_max_memory",
  :default               => "128m",
  :display_name          => "",
  :description           => ""

attribute "resque/redis_vm_pages",
  :default               => "16777216",
  :display_name          => "",
  :description           => ""

attribute "resque/redis_saves",
  :type                  => "array",
  :default               => [["900", "1"], ["300", "10"], ["60", "10000"]],
  :display_name          => "",
  :description           => ""

attribute "resque/redis_slave",
  :default               => "no",
  :display_name          => "",
  :description           => ""

attribute "resque/app_env",
  :default               => "production",
  :display_name          => "",
  :description           => ""
