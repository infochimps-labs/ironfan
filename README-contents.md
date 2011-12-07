
## Recommended directory setup

We recommend you set up your 

    /path/to/{organization}-chefrepo
    │  
    ├── clusters
    │   └── { actual clusters }
    │  
    ├── roles
    │   ├── { roles }
    │   └── { symlinks into vendor/cluster_chef/roles }
    │  
    ├── site-cookbooks                  - directories holding internal cookbooks
    │   └── users
    │  
    ├── cookbooks                       - symlinks to externally maintained cookbooks
    │   ├── @vendor/opscode/...
    │   └── @vendor/cluster_chef/...
    │  
    ├── vendor
    │   ├── opscode
    │   │   └── cookbooks               - git submodule of https://github.com/opscode/cookbooks
    │   │  
    │   └── cluster_chef                - git submodule of https://github.com/infochimps/cluster_chef
    │       ├── site-cookbooks          - systems:     hadoop, cassandra, provides_service, etc.
    │       ├── integration-cookbooks   - integration: connects systems together
    │       ├── meta-cookbooks          - utilities:   provides_service, system_params, can_haz
    │       │  
    │       ├── roles
    │       │  
    │       └── examples
    │           ├── clusters            - example clusters
    │           └── roles               - roles that go with the example clusters
    │  
    ├── certificates
    ├── config
    ├── data_bags
    └── environments

## Recommended knife dir setup

    ~/.chef
    │  
    ├── knife.rb
    ├── knife-user-{user}.rb            - your user-specific knife customizations
    ├── {user}.pem                      - your chef client key
    ├── {organization}-validator.pem    - chef validator key, used to create client keys
    ├── {organization}-credentials.rb   - secret credentials: aws_secret_access_key, etc. Do not version.
    ├── {organization}-cloud.rb      .  - cloud assets: elastic IPs, AMI image ids, etc
    ├── {organization}-keypairs
    │   ├── bonobo.pem
    │   ├── gibbon.pem
    │   ├── client-bonobo-worker-0.pem
    │   └── client-bonobo-worker-0.pem
    └── .gitignore                      - make sure not to version the secret/user-specific stuff (*-keypairs, *-credentials.rb, knife-user-*.rb)

For example, I am user `mrflip` and my organization is `infochimps`, so my tree looks like:

    knife_dir
    │  
    ├── knife.rb
    ├── knife-user-mrflip.rb            
    ├── mrflip.pem                      
    ├── infochimps-validator.pem    
    ├── infochimps-credentials.rb   
    ├── infochimps-cloud.rb      .  
    ├── infochimps-keypairs
    │   ├── bonobo.pem
    │   ├── gibbon.pem
    │   ├── client-bonobo-master-0.pem
    │   └── client-bonobo-worker-1.pem
    └── .gitignore                      




    #
    # Systems
    #

    #
    # A server is something that (typically all, but at least most of)
    # runs a daemon, opens ports, has logs, has directories, etc.
    #
    # if there's only one contender for the title of 
    #
    [:apache,         :server],
    [:cassandra,      :server],
    [:mongodb,        :server],
    [:mysql,          :server],
    [:nfs,            :server],
    [:nginx,          :server],
    [:ntp,            :server],
    [:redis,          :server],
    [:statsd,         :server],
    [:zabbix,         :server],
    [:zookeeper,      :server],
    [:apt_cacher,     :server],
    [:dashpot,        :server], # not dashboard 
    [:resque,         :server],
    [:openssh,        :server],

    # !not extra server: an announcement some cassandra servers make!
    [:cassandra,      :seed],
    [:elasticsearch,  :seed],
    # similarly, a mysql-master is also a mysql-server 
    [:mysql,          :master],
    [:mysql,          :slave ],
    [:redis,          :master],
    [:redis,          :slave ],    

    # where there are lots of server-y things
    # give them their system-specific natural name.
    # If there are multiple server-y names, avoid if possible giving any of them the subsytem name 'server'...

    [:chef,           :expander],
    [:chef,           :server], # ... but don't fight city hall: if its name is server go with server
    [:chef,           :solr],
    [:chef,           :webui],
    [:elasticsearch,  :datanode],
    [:elasticsearch,  :httpnode],
    [:flume,          :master],
    [:ganglia,        :master],
    [:graphite,       :carbon],
    [:graphite,       :dashboard], 
    [:graphite,       :whisper],
    [:hadoop,         :datanode],
    [:hadoop,         :hdfs_fuse],
    [:hadoop,         :jobtracker],
    [:hadoop,         :namenode],
    [:hadoop,         :secondarynn],
    [:hadoop,         :tasktracker],
    [:hbase,          :master],
    [:hbase,          :regionserver],
    [:hbase,          :stargate],
    [:jenkins,        :master],
    [:jenkins,        :worker],      
    [:resque,         :worker],

    #
    # A 'client' means 'I install all the stuff to let you *use* some other
    # component. We're not even sure if these announce.
    #
    [:nfs,            :client],
    [:redis,          :client],
    
    # An 'agent' is a thing that runs and uses that thing. A client is not
    # necessarily an agent.
    [:flume,          :agent],
    [:zabbix,         :agent],
    [:cron,           :agent],
    [:ganglia,        :agent],
    [:bluepill,       :agent],
    
    # The chef-client daemon is in this terminology properly an 'agent' -- if it
    # conformed to the style guide, chef_client would install the runnable, and
    # chef_agent would be the daemon which periodically contacts the chef_server
    # and converges the machine.
    [:chef,           :client],

__________________________________________________________________________
    
    #
    # Discovery / preparation
    #
    [:os_tuning], # https://github.com/37signals/37s_cookbooks/tree/master/sysctl
    [:mountable_volumes],
    [:aws],
    [:virtualbox],
    [:ant],
    
    #
    # Libraries
    #
    [:java],
    [:nodejs],
    [:jruby],
    [:maven],
    [:boost],
    [:thrift],
    [:gecode],
    [:erlang],
    [:python],
    [:ruby],
    
    #
    # Programs
    #
    [:pig],
    [:hive],
    [:rstats],
    
    #
    # Integration
    #
    [:cloudkick],
    [:dash_dash,  :integration]
    [:database],
    [:motd],
    [:papertrail],
    [:port_scan],
    [:route53], # https://github.com/heavywater/community-cookbooks/tree/master/route53
    [:runit],
    [:ufw],
    [:whenever],
    
    # [:s3client], # https://github.com/lusis/lusis-cookbooks/tree/master/s3client
    # [:cube, :???], # https://github.com/heavywater/community-cookbooks/tree/master/cube
    # [:splunk, :???], # https://github.com/cwjohnston/chef-splunk
    # [:noah, :server],  # https://github.com/lusis-cookbooks/noah
    # [:postgresql, :server],
    # [:openldap, :server],
    # [:sftp,           :server],
    # [:god, :monitor],
    # [:rabbitmq, :server],
    # [:couchdb, :server],
    # [:nagios, :agent],
    # [:memcached, :server],
    # [:tokyotyrant, :server],
    # [:zenoss, ???],
    # [:varnish, ???],
    # [:haproxy, ???],
    # [:logrotate, :???],
    # [:rsyslog, :???],
