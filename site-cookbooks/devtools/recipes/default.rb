
# # Follow along with tail -f /var/log/user.log
# function configure_devtools {
#   apt-get -y update  ;
#   apt-get -y upgrade ;
#   #
#   apt-get -y install git-core cvs subversion exuberant-ctags tree zip openssl liblzo2-dev;
#   apt-get -y install libpcre3-dev libbz2-dev libonig-dev libidn11-dev libxml2-dev libxml2-utils libxslt1-dev libevent-dev;
#   apt-get -y install emacs emacs-goodies-el emacsen-common ;
#   apt-get -y install ruby rubygems ruby1.8-dev ruby-elisp irb ri rdoc python-setuptools python-dev;
#   # Distributed database
#   apt-get -y install libtokyocabinet-dev tokyocabinet-bin ;
#   # Java dev
#   apt-get -y install ant   # TODO: ivy
#   # Python
#   easy_install simplejson boto ctypedbytes dumbo
#   # # Un-screwup Ruby Gems
#   # gem install --no-rdoc --no-ri rubygems-update --version=1.3.6 ; /var/lib/gems/1.8/bin/update_rubygems; gem update --no-rdoc --no-ri --system ; gem --version ;
#   # GEM_COMMAND="gem install --no-rdoc --no-ri --source=http://gemcutter.org"
#   # # Ruby gems: Basic utility and file format gems
#   # $GEM_COMMAND extlib oniguruma fastercsv json libxml-ruby htmlentities addressable uuidtools
#   # # Ruby gems: Wukong's friends
#   # $GEM_COMMAND monkeyshines edamame configliere wukong
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

# #
# # This is made of kludge.  Among other things, you have to create the users in
# # the right order -- and ensure none have been made before -- or your uid's
# # won't match the ones on the EBS volume.
# #
# # This also creates and sets permissions on the HDFS home directories, which
# # might be best left off. (It depends on the HDFS coming up in time
# #
# function make_user_accounts {
#   groupadd supergroup
#   for newuser in $USER_ACCOUNTS ; do
#     adduser $newuser --disabled-password --gecos "";
#     usermod -a -G supergroup,sudo,admin  $newuser ;
#     sudo -u hadoop hadoop dfs -mkdir          /user/$newuser
#     sudo -u hadoop hadoop dfs -chown $newuser /user/$newuser
#   done
# }
#
# function cleanup {
#   apt-get -y autoremove
#   apt-get -y clean
#   updatedb
# }
#
# install_nfs
# configure_nfs
# register_auto_shutdown
# update_repo
# install_user_packages
# install_hadoop
# install_cloudera_desktop
# configure_hadoop
# configure_cloudera_desktop
# start_nfs
# configure_devtools
#
# if $IS_MASTER ; then
#   setup_web
#   start_hadoop_master
#   # start_cloudera_desktop
# else
#   start_hadoop_slave
# fi
# make_user_accounts
# cleanup

# ====
#
# Build http://github.com/kevinweil/hadoop-lzo (git://github.com/kevinweil/hadoop-lzo.git)
# Place the hadoop-lzo-*.jar somewhere on your cluster nodes; we use /usr/local/hadoop/lib
# Place the native hadoop-lzo binaries (which are JNI-based and used to interface with the lzo library directly) on your cluster as well; we use /usr/local/hadoop/lib/native/<arch>/
# Make sure the directory /usr/local/hadoop/lib is part of HADOOP_CLASSPATH in hadoop-env.sh
#    export HADOOP_CLASSPATH=/path/to/your/hadoop-gpl-compression.jar
#    export JAVA_LIBRARY_PATH=/path/to/hadoop-gpl-native-libs:/path/to/standard-hadoop-native-libs
# And comment out JAVA_LIBRARY_PATH='' in your ..../bin/hadoop
# Index files with
#    hadoop jar /path/to/your/hadoop-gpl-compression.jar com.hadoop.compression.lzo.LzoIndexer big_file.lzo
#
# Add to core-site.xml:
#
#     <property>
#     <name>io.compression.codecs</name>
#     <value>org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.BZip2Codec,com.hadoop.compression.lzo.LzoCodec,com.hadoop.compression.lzo.LzopCodec</value>
#     </property>
#     <property>
#     <name>io.compression.codec.lzo.class</name>
#     <value>com.hadoop.compression.lzo.LzoCodec</value>
#     </property>
#
# Add to mapred-site.xml:
#
#     <property>
#       <name>mapred.child.env</name>
#       <value>JAVA_LIBRARY_PATH=/path/to/your/native/hadoop-lzo/libs</value>
#     </property>
#     <property>
#       <name>mapred.map.output.compression.codec</name>
#       <value>com.hadoop.compression.lzo.LzoCodec</value>
#     </property>
#
# Streaming:  -inputformat com.hadoop.mapred.DeprecatedLzoTextInputFormat
# Pig:        LOAD '$INPUT_FILES' USING ...Lzo[]Loader()
#
# =====
