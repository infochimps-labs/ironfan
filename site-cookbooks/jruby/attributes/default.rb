default[:jruby][:home_dir]          = '/usr/local/share/jruby'

default[:jruby][:version]           = "1.6.5"
default[:jruby][:release_url]       = "http://jruby.org.s3.amazonaws.com/downloads/#{node[:jruby][:version]}/jruby-bin-#{node[:jruby][:version]}.tar.gz"

default[:java][:java_home]         = '/usr/lib/jvm/java-6-sun/jre'
