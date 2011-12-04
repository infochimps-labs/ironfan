module ClusterChef
  module Discovery
    module_function

    def dump_aspects(run_context)
      [
        [:cassandra,      :server],
        [:chef_client,    :client],
        # [:dash_dash,    :dashboard],
        [:cluster_chef,   :dashboard],
        [:cron,           :daemon],
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
        [:nfs,            :server],
        [:nginx,          :server],
        [:ntp,            :server],
        [:redis,          :server],
        [:resque,         :dashboard],
        [:ssh,            :daemon],
        [:statsd,         :server],
        [:zookeeper,      :server],

        # [:apache,         :server],
        # [:mongodb,        :server],
        # [:mysql,          :server],
        # [:zabbix,         :monitor],
        # [:zabbix,         :server],
        # [:goliath,        :app],
        # [:unicorn,        :app],
        # [:apt_cacher,     :server],
        # [:bluepill,       :monitor],
        # [:resque,         :worker],

      ].each do |sys, component|
        aspects = announce(run_context, sys, component)
        pad = ([""]*20)
        dump_line = dump(aspects) || []
        puts( "%-15s\t%-15s\t%-23s\t%-51s|%-15s|#{"%-7s\t"*12}" % [sys, component, dump_line, pad].flatten )
      end

    end
  end
end
