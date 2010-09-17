package "hadoop-0.20-fuse"
include_recipe "runit"

directory "/hdfs" do
  owner    "root"
  group    "root"
  mode     "0755"
  action   :create
  recursive true
end

runit_service "hdfs_fuse"
