maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "Apply OS-specific tuning using parameters set by recipes and roles"



recipe           "tuning::default",                    "Calls out to the right tuning recipe based on platform"
recipe           "tuning::ubuntu",                     "Applies tuning for Ubuntu systems"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "tuning/ulimit",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "tuning/overcommit_memory",
  :display_name          => "",
  :description           => "",
  :default               => "1"

attribute "tuning/overcommit_ratio",
  :display_name          => "",
  :description           => "",
  :default               => "100"

attribute "tuning/swappiness",
  :display_name          => "",
  :description           => "",
  :default               => "5"
