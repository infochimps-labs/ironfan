directory "/usr/local/src" do
  mode      '0775'
  owner     'root'
  group     'admin'
  action    :create
  recursive true
end

cassandra_install_pkg = File.basename(node[:cassandra][:install_url])
cassandra_install_dir = cassandra_install_pkg.gsub(%r{(?:-bin)?\.tar\.gz}, '')
# Chef::Log.info [cassandra_install_pkg, cassandra_install_dir].inspect

remote_file "/usr/local/src/"+cassandra_install_pkg do
  source    node[:cassandra][:install_url]
  mode      "0644"
  action :create
end

bash 'install from tarball' do
  user         'root'
  cwd          '/usr/local/share'
  code <<EOF
  tar xzf /usr/local/src/#{cassandra_install_pkg}
  cd  #{cassandra_install_dir}
  mv                conf/storage-conf.xml conf/storage-conf.xml.orig
  ln -nfs /etc/cassandra/storage-conf.xml conf/storage-conf.xml
  if [ -e build.xml ] ; then
    ant ivy-retrieve
    ant build
  fi
  chmod a+x bin/*
  true
EOF
  not_if{ File.directory?("/usr/local/share/"+cassandra_install_dir) && (not Dir['/usr/local/share/apache-cassandra/build/apache-cassandra-*.jar'].blank?) }
end

link "/usr/local/share/cassandra" do
  to "/usr/local/share/"+cassandra_install_dir
  action :create
end

link "/usr/local/share/cassandra/cassandra.in.sh" do
  to "/usr/local/share/cassandra/bin/cassandra.in.sh"
  action :create
end

link "/usr/sbin/cassandra" do
  to "/usr/local/share/cassandra/bin/cassandra"
  action :create
end
