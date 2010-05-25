#
# Make sure hadoop is the owner of all files in the special hadoop dirs.
#
dfs_name_dirs.each{      |dir| ensure_hadoop_owns_hadoop_dirs(dir) }
dfs_data_dirs.each{      |dir| ensure_hadoop_owns_hadoop_dirs(dir) }
fs_checkpoint_dirs.each{ |dir| ensure_hadoop_owns_hadoop_dirs(dir) }
mapred_local_dirs.each{  |dir| ensure_hadoop_owns_hadoop_dirs(dir) }




