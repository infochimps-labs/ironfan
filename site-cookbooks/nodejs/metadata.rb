maintainer       "Nathaniel Eliot - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures nodejs"

depends          "python"


%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "nodejs/git_uri",
  :default               => "https://github.com/joyent/node.git",
  :display_name          => "",
  :description           => ""

attribute "nodejs/jobs",
  :default               => "2",
  :display_name          => "",
  :description           => ""

attribute "nodejs/src_path",
  :default               => "/usr/src/nodejs",
  :display_name          => "",
  :description           => ""

attribute "nodejs/bin_path",
  :default               => "/usr/local/bin/node",
  :display_name          => "",
  :description           => ""
