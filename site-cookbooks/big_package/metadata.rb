maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "A bunch of fun packages"


recipe           "big_package::default",               "Base configuration for big_package"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "ruby/version",
  :display_name          => "",
  :description           => "",
  :default               => "1.8"

attribute "pkg_sets/install",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["base", "dev", "sysadmin"]

attribute "pkg_sets/pkgs/base",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["tree", "git", "zip", "openssl"]

attribute "pkg_sets/pkgs/dev",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["emacs23-nox", "elinks", "colordiff", "ack", "exuberant-ctags"]

attribute "pkg_sets/pkgs/sysadmin",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["ifstat", "atop", "htop", "tree", "chkconfig", "sysstat", "htop", "nmap"]

attribute "pkg_sets/pkgs/text",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["libidn11-dev", "libxml2-dev", "libxml2-utils", "libxslt1-dev", "tidy"]

attribute "pkg_sets/pkgs/ec2",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["s3cmd", "ec2-ami-tools", "ec2-api-tools"]

attribute "pkg_sets/pkgs/vagrant",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["ifstat", "htop", "tree", "chkconfig", "sysstat", "htop", "nmap"]

attribute "pkg_sets/pkgs/python",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["python-dev", "python-setuptools", "pythong-simplejson"]

attribute "pkg_sets/pkgs/datatools",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["r-base", "r-base-dev", "x11-apps", "eog", "texlive-common", "texlive-binaries", "dvipng", "ghostscript", "latex", "libfreetype6", "python-gtk2", "python-gtk2-dev", "python-wxgtk2.8"]

attribute "pkg_sets/pkgs/emacs",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["emacs23-nox", "emacs23-el", "python-mode", "ruby1.9.1-elisp", "org-mode"]

attribute "pkg_sets/gems/base",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["bundler", "rake"]

attribute "pkg_sets/gems/dev",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["activesupport", "activemodel", "extlib", "json", "yajl-ruby", "awesome_print", "addressable", "cheat", "yard", "jeweler", "rspec", "watchr", "pry", "configliere", "gorillib", "highline", "formatador", "choice", "rest-client", "wirble", "hirb"]

attribute "pkg_sets/gems/sysadmin",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "pkg_sets/gems/text",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["nokogiri", "erubis", "i18n"]

attribute "pkg_sets/gems/ec2",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["fog", "right_aws"]

attribute "pkg_sets/gems/vagrant",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["vagrant"]
