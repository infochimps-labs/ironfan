maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "A bunch of fun packages"



%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "ruby/version",
  :default               => "1.8",
  :display_name          => "",
  :description           => ""
