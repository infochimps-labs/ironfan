package "jruby" do
  action :install
end

%w[
   extlib fastercsv json yajl-ruby libxml-ruby htmlentities addressable
   uuidtools configliere right_aws whenever
   rest-client oauth json crack cheat
   echoe jeweler yard net-proto net-scp net-sftp net-ssh idn
   rails wirble
   wukong cassandra redis
   dependencies
   imw chimps
].each do |pkg|
  gem_package pkg do
    action :install
    gem_binary '/usr/bin/jruby'
  end
end

gem_package("nokogiri"){action :install ; version "1.4.2" }
gem_package("hpricot"){ action :install ; version "0.8.2" }

