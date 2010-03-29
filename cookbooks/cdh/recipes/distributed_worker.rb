
  # if which dpkg &> /dev/null; then
  #   apt-get -y install $HADOOP-datanode
  #   apt-get -y install $HADOOP-tasktracker
  # elif which rpm &> /dev/null; then
  #   yum install -y $HADOOP-datanode
  #   yum install -y $HADOOP-tasktracker
  #   chkconfig --add $HADOOP-datanode
  #   chkconfig --add $HADOOP-tasktracker
  # fi
  #
  # service $HADOOP-datanode start
  # service $HADOOP-tasktracker start
