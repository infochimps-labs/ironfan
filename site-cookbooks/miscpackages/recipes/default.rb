
%w[
  g++ ec2-api-tools ec2-ami-tools ;
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
# sudo gem install dustin-beanstalk-client  --source=http://gems.github.com ;

# boost pkgconfig

# cassandra thrift

#   # # Pig Piggybank
#   # PIG_DIR=/usr/lib/pig${PIG_VERSION:+-${PIG_VERSION}}
#   # if [ -f $PIG_DIR/contrib/piggybank/java/piggybank.jar ] ; then
#   #   echo "piggybank installed"
#   # else
#   #   export CLASSPATH=$( echo `/bin/ls /usr/lib/pig/*.jar /usr/lib/hadoop/*.jar /usr/lib/hadoop/lib/*.jar` | ruby -e 'puts $stdin.read.chomp.gsub(/\s/, ":")' )
#   #   ( cd /usr/lib/pig/contrib ;
#   #     svn co http://svn.apache.org/repos/asf/hadoop/pig/trunk/${PIG_VERSION-trunk}/piggybank ;
#   #     cd piggybank/java ;
#   #     ant )
#   # fi
# }
