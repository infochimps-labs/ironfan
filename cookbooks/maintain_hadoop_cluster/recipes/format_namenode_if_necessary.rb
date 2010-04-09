
#
# Format Namenode
#
execute 'format_namenode' do
  command %Q{yes 'Y' | hadoop namenode -format}
  user 'hadoop'
  creates '/mnt/hadoop/hdfs/name/current/VERSION'
  creates '/mnt/hadoop/hdfs/name/current/fsimage'
end
