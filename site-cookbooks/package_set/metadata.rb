maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "Installs extra packages that don't warrant their own cookbook (tree, htop, colordiff and so on), yet still provides visibility, dev-vs-production tradeoffs, and fine-grained version control where necessary."

recipe           "package_set::default",               "Base configuration for package_set"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "package_set/install",
  :display_name          => "Package sets to install",
  :description           => "Choose the package sets to install. See package_set/pkgs and package_set/gems for their contents.",
  :type                  => "array",
  :default               => ["base", "dev", "sysadmin"]

attribute "package_set/pkgs/base",
  :display_name          => "Base set of packages, suitable for all machines",
  :description           => "",
  :type                  => "array",
  :default               => ["tree", "git", "zip", "openssl"]

attribute "package_set/pkgs/dev",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["emacs23-nox", "elinks", "colordiff", "ack", "exuberant-ctags"]

attribute "package_set/pkgs/sysadmin",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["ifstat", "atop", "htop", "tree", "chkconfig", "sysstat", "htop", "nmap"]

attribute "package_set/pkgs/text",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["libidn11-dev", "libxml2-dev", "libxml2-utils", "libxslt1-dev", "tidy"]

attribute "package_set/pkgs/ec2",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["s3cmd", "ec2-ami-tools", "ec2-api-tools"]

attribute "package_set/pkgs/vagrant",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["ifstat", "htop", "tree", "chkconfig", "sysstat", "htop", "nmap"]

attribute "package_set/pkgs/python",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["python-dev", "python-setuptools", "pythong-simplejson"]

attribute "package_set/pkgs/datatools",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["r-base", "r-base-dev", "x11-apps", "eog", "texlive-common", "texlive-binaries", "dvipng", "ghostscript", "latex", "libfreetype6", "python-gtk2", "python-gtk2-dev", "python-wxgtk2.8"]

attribute "package_set/pkgs/emacs",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["emacs23-nox", "emacs23-el", "python-mode", "ruby1.9.1-elisp", "org-mode"]

attribute "package_set/gems/base",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["bundler", "rake"]

attribute "package_set/gems/dev",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["activesupport", "activemodel", "extlib", "json", "yajl-ruby", "awesome_print", "addressable", "cheat", "yard", "jeweler", "rspec", "watchr", "pry", "configliere", "gorillib", "highline", "formatador", "choice", "rest-client", "wirble", "hirb"]

attribute "package_set/gems/sysadmin",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "package_set/gems/text",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["nokogiri", "erubis", "i18n"]

attribute "package_set/gems/ec2",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["fog", "right_aws"]

attribute "package_set/gems/vagrant",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["vagrant"]
