# This stuff needs to be owned by hadoop

runit_service "cassandra"

[ "/var/lib/cassandra", "/var/log/cassandra",
  node[:cassandra][:data_file_dirs],
  node[:cassandra][:commitlog_dir],
].flatten.each do |cassandra_dir|
  directory cassandra_dir do
    owner    "hadoop"
    group    "root"
    mode     "0755"
    action   :create
    recursive true
  end
end

bash 'move updated json libs to hadoop lib' do
  code <<EOF
  rm /usr/lib/hadoop/lib/*jackson*.jar
  cp /usr/local/share/cassandra/lib/*jackson*.jar /usr/lib/hadoop/lib/
EOF
end
