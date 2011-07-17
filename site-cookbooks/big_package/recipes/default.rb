Chef::Log.debug [ node[:ruby] ].inspect + "\n\n!!!\n\n"

%w[
  git-core cvs subversion exuberant-ctags tree zip liblzo2-dev
  libpcre3-dev libbz2-dev libidn11-dev libxml2-dev libxml2-utils libxslt1-dev libevent-dev
  ant openssl colordiff ack htop makepasswd sysstat
  g++ python-setuptools python-dev
  s3cmd elinks
  tidy
  ifstat
].each do |pkg|
  package pkg
end

%w[
   extlib rails fastercsv json yajl-ruby
   addressable fog cheat configliere wukong gorillib
].each do |gem_pkg|
  gem_package gem_pkg do
    action :install
  end
end
