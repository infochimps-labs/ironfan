
#
# Link hbase, zookeeper, etc jars to $PIG_HOME/lib
#
node[:pig][:extra_jars].each do |jar|
  link File.join(node[:pig][:home_dir], 'lib', File.basename(jar)) do
    to        jar
    action    :create
  end
end

#
# Link hbase configuration to $PIG_HOME/conf
#
node[:pig][:extra_confs].each do |xml_conf|
  link "/usr/local/share/pig/conf/#{File.basename(xml_conf)}" do
    to xml_conf
    action :create
  end
end
