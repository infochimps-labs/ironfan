cassandra_home        = node[:cassandra][:cassandra_home]
cassandra_install_dir = cassandra_home + '-git'

directory File.dirname(cassandra_home) do
  mode         '0755'
  owner        'root'
  group        'admin'
  action       :create
  recursive true
end

git cassandra_install_dir do
  repository    node[:cassandra][:git_repo]
  action        :sync
  group         'admin'
  revision      node[:cassandra][:git_revision]
end

bash 'install from source' do
  user         'root'
  cwd          cassandra_install_dir
  code <<EOF
  ant jar
  ant avro-generate
  mv                conf/cassandra.yaml conf/cassandra.yaml.orig
  ln -nfs #{cassandra_install_dir}/conf/* /etc/cassandra/
  chmod a+x bin/*
  true
EOF
  only_if{ Dir["#{cassandra_install_dir}/build/apache-cassandra-*.jar"].blank? }
end

link cassandra_home do
  to            cassandra_install_dir
  action        :create
end


# link "#{cassandra_home}/cassandra.in.sh" do
#   to          "#{cassandra_home}/bin/cassandra.in.sh"
#   action      :create
# end
#
# link "/usr/sbin/cassandra" do
#   to          "#{cassandra_home}/bin/cassandra"
#   action      :create
# end
