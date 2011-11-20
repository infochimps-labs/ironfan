maintainer       "Jacob Perkins - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures jruby"

depends          "java"

recipe           "jruby::default",                     "Base configuration for jruby"
recipe           "jruby::gems",                        "Gems"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "jruby/home_dir",
  :display_name          => "Installed location of jruby",
  :description           => "",
  :default               => "/usr/lib/jruby"

attribute "jruby/release_url",
  :display_name          => "JRuby release tarball to install",
  :description           => "",
  :default               => "http://jruby.org.s3.amazonaws.com/downloads/1.6.5/jruby-bin-1.6.5.tar.gz"

attribute "java/java_home",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/lib/jvm/java-6-sun/jre"
