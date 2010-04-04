


%w[
  git-core cvs subversion exuberant-ctags tree zip liblzo2-dev
  libpcre3-dev libbz2-dev libonig-dev libidn11-dev libxml2-dev libxml2-utils libxslt1-dev libevent-dev
  ruby-elisp python-setuptools python-dev
  openssl libssl-dev libcurl4-openssl-dev libopenssl-ruby
  ant
].each do |pkg|
  package pkg
end


# packages *%w[ libtokyocabinet-dev tokyocabinet-bin ]

# easy_install simplejson boto ctypedbytes dumbo


# gem extlib oniguruma fastercsv json libxml-ruby htmlentities addressable uuidtools
#     monkeyshines edamame configliere wukong

# boost pkgconfig

# cassandra thrift
