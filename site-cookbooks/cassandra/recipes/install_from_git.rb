#
# Cookbook Name::       cassandra
# Description::         Install From Git
# Recipe::              install_from_git
# Author::              Benjamin Black
#
# Copyright 2011, Benjamin Black
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

home_dir        = node[:cassandra][:home_dir]
cassandra_install_dir = home_dir + '-git'

include_recipe "java"
package 'sun-java6-jdk'
package 'sun-java6-bin'

standard_dirs('cassandra') do
  directories   :home_dir
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

link home_dir do
  to            cassandra_install_dir
  action        :create
end

%w[cassandra schematool cassandra-cli clustertool nodetool sstablekeys].each do |util|
  link "/usr/local/bin/#{util}" do
    to          "#{home_dir}/bin/#{util}"
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
