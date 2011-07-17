Chef::Log.debug [ node[:ruby] ].inspect + "\n\n!!!\n\n"

packages_list = %w[
  git-core cvs subversion exuberant-ctags tree zip liblzo2-dev
  libpcre3-dev libbz2-dev libidn11-dev libxml2-dev libxml2-utils libxslt1-dev libevent-dev
  ant openssl colordiff ack htop makepasswd sysstat
  g++ python-setuptools python-dev
  s3cmd elinks
  tidy
  ifstat
]

if node[:lsb][:release].to_f > 9.0
  packages_list += %w[ ec2-ami-tools ]
end

packages_list.each do |pkg|
  package pkg
end

%w[
   extlib rails fastercsv json yajl-ruby
   addressable fog cheat configliere wukong gorillib
].each do |pkg|
  gem_package pkg do
    action :install
  end
end
