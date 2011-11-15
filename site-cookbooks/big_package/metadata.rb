maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "A bunch of fun packages"


recipe           "big_package::data_analysis_tools",   "Data Analysis Tools"
recipe           "big_package::default",               "Default"
recipe           "big_package::emacs",                 "Emacs"
recipe           "big_package::other",                 "Other"
recipe           "big_package::python",                "Python"
recipe           "big_package::ruby-datamapper",       "Ruby Datamapper"
recipe           "big_package::ruby-fix_rubygems_version", "Ruby Fix Rubygems Version"
recipe           "big_package::ruby",                  "Ruby"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "ruby/version",
  :display_name          => "",
  :description           => "",
  :default               => "1.8"
