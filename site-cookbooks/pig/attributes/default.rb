
default[:apt][:cloudera][:force_distro] = nil # override distro name if cloudera doesn't have yours yet
default[:apt][:cloudera][:release_name] = 'cdh3u2'

default[:pig][:home_dir]          = '/usr/lib/pig'

default[:pig][:release_url]       = "http://apache.mirrors.tds.net/pig/pig-0.9.1/pig-0.9.1.tar.gz"
default[:java][:java_home]        = '/usr/lib/jvm/java-6-sun/jre'

default[:pig][:combine_splits]    = "true"
