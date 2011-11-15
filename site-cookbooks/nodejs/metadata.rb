maintainer       "Nathaniel Eliot - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures nodejs"

depends          "python"

recipe           "nodejs::compile",                    "Compile"
recipe           "nodejs::default",                    "Default"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "nodejs/git_uri",
  :display_name          => "",
  :description           => "",
  :default               => "https://github.com/joyent/node.git"

attribute "nodejs/jobs",
  :display_name          => "",
  :description           => "",
  :default               => "2"

attribute "nodejs/src_path",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/src/nodejs"

attribute "nodejs/bin_path",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/local/bin/node"
