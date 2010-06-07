packages_list = %w[
  git-core cvs subversion exuberant-ctags tree zip liblzo2-dev
  libpcre3-dev libbz2-dev libonig-dev libidn11-dev libxml2-dev libxml2-utils libxslt1-dev libevent-dev
  ant openssl colordiff ack htop makepasswd
  g++ python-setuptools python-dev
  s3cmd
  tidy
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
