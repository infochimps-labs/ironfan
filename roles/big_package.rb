require File.dirname(__FILE__)+'/../settings'

# Install with
#   knife role from file roles/base_role.rb

name 'base_role'
description 'top level attributes, applies to all nodes'

run_list *%w[

  ]


#   apt-get -y install git-core cvs subversion exuberant-ctags tree zip openssl liblzo2-dev;
#   apt-get -y install libpcre3-dev libbz2-dev libonig-dev libidn11-dev libxml2-dev libxml2-utils libxslt1-dev libevent-dev;
#   apt-get -y install emacs emacs-goodies-el emacsen-common ;
#   apt-get -y install ruby rubygems ruby1.8-dev ruby-elisp irb ri rdoc python-setuptools python-dev;
#   # Distributed database
#   apt-get -y install libtokyocabinet-dev tokyocabinet-bin ;
#   # Java dev
#   apt-get -y install ant   # TODO: ivy

#   easy_install simplejson boto ctypedbytes dumbo

#   # # Ruby gems: Basic utility and file format gems
#   # $GEM_COMMAND extlib oniguruma fastercsv json libxml-ruby htmlentities addressable uuidtools configliere wukong

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

