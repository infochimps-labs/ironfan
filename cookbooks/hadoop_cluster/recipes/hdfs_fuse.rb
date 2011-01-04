class Chef::Recipe; include HadoopCluster ; end

hadoop_package "fuse"
include_recipe "runit"

directory "/hdfs" do
  owner    "hdfs"
  group    "supergroup"
  mode     "0755"
  action   :create
  recursive true
  # not_if{ File.exists?('/hdfs') }
end

execute "add fuse module to kernel" do
  command %Q{/sbin/modprobe fuse; true}
end

execute 'fix fuse configuration to allow hadoop' do
  command %Q{sed -i -e 's|#user_allow_other|user_allow_other|' /etc/fuse.conf && chown hdfs:hadoop /etc/fuse.conf}
  user 'root'
  not_if "egrep '^user_allow_other' /etc/fuse.conf"
end

# this is clearly garbage, why isn't this a node[:os_arch] something?
java_home_dir_mapping = {
  'x86_64' => 'amd64',
  'i686'   => 'i386'
}

template_parameters = {
  :os_arch          => java_home_dir_mapping[ node[:kernel][:machine] ],
  :namenode_address => namenode_address
}
Chef::Log.info template_parameters.inspect
runit_service "hdfs_fuse" do
  finish_script true
  options(template_parameters)
end
