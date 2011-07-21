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
  ant build jar gen-thrift-py
  mv                conf/cassandra.yaml conf/cassandra.yaml.orig
  ln -nfs #{cassandra_install_dir}/conf/* /etc/cassandra/
  chmod a+x bin/*
  true
EOF
  only_if{ Dir["#{cassandra_install_dir}/build/apache-cassandra-*.jar"].nil? }
end

link cassandra_home do
  to            cassandra_install_dir
  action        :create
end

%w[cassandra schematool cassandra-cli clustertool nodetool sstablekeys].each do |util|
  link "/usr/local/bin/#{util}" do
    to          "#{cassandra_home}/bin/#{util}"
    action      :create
  end
end

# check out other version
# patches
# sudo apt-get install -y asciidoc source-highlight libboost-regex-dev libboost-dev libboost-system-dev libboost-dev
# svn export --force . build/avro-src-$VERSION || rsync -alvi ./ ./build/avro-src-$VERSION --exclude={build,.git,.svn,dist,*.cache,lang/c++/config,lang/py/avro.egg-info,lang/ruby/{pkg,Manifest,avro.gemspec}}

bash 'Push compatible Jackson into hadoop if hadoop exists' do
  code <<EOF
mv /usr/lib/hadoop/lib/jackson-*1.0.1.jar /tmp && true ;
cp /usr/local/share/cassandra/lib/jackson-* /usr/lib/hadoop/lib/
true
EOF
  only_if{ File.exists?('/usr/lib/hadoop/lib') }
  only_if{ Dir['/usr/lib/hadoop/lib/jackson*1.[456789]*'].nil? }
end
