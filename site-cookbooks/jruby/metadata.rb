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
