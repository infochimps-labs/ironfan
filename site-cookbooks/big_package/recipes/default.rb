packages_list = %w[
  git-core cvs subversion exuberant-ctags tree zip liblzo2-dev
  libpcre3-dev libbz2-dev libonig-dev libidn11-dev libxml2-dev libxml2-utils libxslt1-dev libevent-dev
  ant openssl colordiff ack htop makepasswd sysstat
  g++ python-setuptools python-dev
  s3cmd
  tidy
  ifstat
]
if node[:lsb][:release].to_f > 9.0
  packages_list += %w[ ec2-api-tools ec2-ami-tools ]
end
if node[:lsb][:release].to_f > 10.0
  packages_list += %w[ diffutils ]
end

packages_list.each do |pkg|
  package pkg
end

%w[
   extlib oniguruma fastercsv json yajl-ruby crack htmlentities addressable
   uuidtools configliere fog right_aws whenever rest-client cheat
   rails wirble wukong
].each do |pkg|
  gem_package pkg do
    action :install
  end
end

package "emacs23-nox" do
  action :install
end
%w[
  erlang-mode python-mode ruby-elisp ruby1.8-elisp php-mode org-mode
  mmm-mode css-mode html-helper-mode lua-mode
].each do |pkg|
  package pkg do
    action :install
  end
end
