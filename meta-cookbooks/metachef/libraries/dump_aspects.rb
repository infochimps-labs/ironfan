module ClusterChef
  module Discovery
    module_function

    def dump_aspects(run_context)
      [
        [:cassandra,      :server],
        [:chef_client,    :client],
        # [:dash_dash,    :dashboard],
        [:metachef,   :dashboard],
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
        puts( "%-15s\t%-15s\t%-23s\t| %-51s\t| %-12s\t#{"%-7s\t"*12}" % [sys, component, dump_line, pad].flatten )
      end

      run_context.resource_collection.select{|r| r.resource_name.to_s == 'service' }.each{|r| p [r.name, r.action] }
    end


    def dump(aspects)
      return if aspects.empty?
      vals = [
        aspects[:daemon    ].map{|asp|  asp.name                }.join(",")[0..20],
        aspects[:port      ].map{|asp| "#{asp.flavor}=#{asp.port_num}" }.join(","),
        aspects[:dashboard ].map{|asp|  asp.name                }.join(","),
        aspects[:log       ].map{|asp|  asp.name                }.join(","),
        DirectoryAspect::ALLOWED_FLAVORS.map do |flavor|
          asp = aspects[:directory ].detect{|asp| asp[:flavor] == flavor }
          # asp ? "#{asp.flavor}=#{asp.path}" : ""
          asp ? asp.name : ""
        end,
        ExportedAspect::ALLOWED_FLAVORS.map do |flavor|
          asp = aspects[:exported ].detect{|asp| asp[:flavor] == flavor }
          # asp ? "#{asp.flavor}=#{asp.files.join(",")}" : ""
          asp ? asp.name : ""
        end,
      ]
      vals
    end

  end
end
