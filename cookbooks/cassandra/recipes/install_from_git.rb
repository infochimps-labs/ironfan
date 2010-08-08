cassandra_home    = node[:cassandra][:cassandra_home]
cassandra_install_dir = cassandra_home + '-git'

directory File.dirname(cassandra_home) do
  mode         '0755'
  owner        'root'
  group        'admin'
  action       :create
  recursive true
end

git cassandra_install_dir do
  repository    cassandra_git_repo
  action        :sync
  group         'admin'
  revision      node[:cassandra][:git_revision] || 'HEAD'
  depth      	1
  enable_submodules true
end

bash 'install from source' do
  user         'root'
  cwd          cassandra_install_dir
  code <<EOF
  ant jar
  ant avro-generate
  mv                conf/storage-conf.xml conf/storage-conf.xml.orig
  ln -nfs /etc/cassandra/storage-conf.xml conf/storage-conf.xml
  chmod a+x bin/*
  true
EOF
  only_if{ Dir["#{cassandra_install_dir}/build/apache-cassandra-*.jar"].blank? }
end

link cassandra_home do
  to        	cassandra_install_dir
  action 	:create, :modify
end


# link "#{cassandra_home}/cassandra.in.sh" do
#   to          "#{cassandra_home}/bin/cassandra.in.sh"
#   action      :create
# end
# 
# link "/usr/sbin/cassandra" do
#   to          "#{cassandra_home}/bin/cassandra"
#   action      :create, :modify
# end
