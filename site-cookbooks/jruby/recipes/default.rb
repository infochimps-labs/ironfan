#
# Cookbook Name:: jruby
# Recipe:: default
#
# Copyright 2011, Infochimps, Inc.
#
#

bash "install_jruby_from_tarball" do
user "root"
  cwd "/tmp"
  code <<-EOH
  wget http://jruby.org.s3.amazonaws.com/downloads/1.5.6/jruby-bin-1.5.6.tar.gz
  cd /usr/local/lib
  tar -xzf /tmp/jruby-bin-1.5.6.tar.gz
  EOH
  not_if "test -d /usr/local/lib/jruby-1.5.6"
end

link "/usr/lib/jruby" do
  to "/usr/local/lib/jruby-1.5.6"
end

%w[ jruby jrubyc jruby.rb jirb ].each do |file|
  link "/usr/bin/#{file}" do
    to "/usr/lib/jruby/bin/#{file}"
  end
end
