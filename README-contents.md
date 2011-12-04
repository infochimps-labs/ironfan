
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
    [:apache,         :server],
    [:cassandra,      :server],
    [:chef,           :client],
    [:cron,           :daemon],
    [:cluster_chef,   :dashboard],
    # [:dash_dash,    :dashboard],
    [:elasticsearch,  :datanode],
    [:elasticsearch,  :httpnode],
    [:flume,          :client],
    [:flume,          :master],
    [:ganglia,        :master],
    [:ganglia,        :monitor],
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
    [:mongodb,        :server],
    [:mysql,          :server],
    [:nfs,            :client],
    [:nfs,            :server],
    [:nginx,          :server],
    [:ntp,            :server],
    [:redis,          :server],
    [:resque,         :dashboard],
    [:openssh,        :daemon],
    [:statsd,         :server],
    [:zabbix,         :monitor],
    [:zabbix,         :server],
    [:zookeeper,      :server],
    
    [:apt_cacher,     :server],
    [:bluepill,       :monitor],
    [:goliath,        :app],
    [:unicorn,        :app],
    [:resque,         :worker],

    [:chef,           :dashboard],
    [:chef,           :expander],
    [:chef,           :server],
    [:chef,           :solr],
    [:jenkins,        :master],
    [:jenkins,        :worker],
    
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
