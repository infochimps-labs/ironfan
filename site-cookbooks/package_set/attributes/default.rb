#
# All but the most hermetic production machines benefit from certain base
# packages -- git, htop, libxml, etc -- be present. Creating a stupid one-line
# cookbook for each is overkill and clutters your runlist. Having a fixed
# 'big_dumping_ground_for_packages' is a proven disaster -- one coder's
# convenience gems is anothers' bundler hell.
#
# Package sets provide
# * visibility: I know *exactly* which miscellaneous packages are installed
# * package sets are repeatable and match the machine's purpose: dev boxes get a
#   variety of kitchen sinks, production boxes get only bare essentials.
# * Fine-grained control over versions, and ability to knock out a conflicting
#   package.
#
# The package_set attribute group defines what package sets to install, and the
# contents of those package sets.
#
# Choose the package sets to install by setting `node[:package_set][:install]`. The
# default is
#
#     default[:package_set][:install] = %w[ base dev sysadmin ]
#
# Targets for `package` resource go in `node[:package_set][:pkgs][{set_name}]`,
# targets for `gem_package` go in `node[:package_set][:gems][{set_name}]`, and so
# forth. For instance, the 'base' group is defined as
#
#     default[:package_set][:pkgs][:base] = %w[ tree git zip openssl ]
#     default[:package_set][:gems][:base] = %w[ bundler rake ]
#
# In your clusters file or a role, you can both specify which sets (if any) the
# machine installs, and modify (for that node or role only) what packages are
# in any given group.
#
# Defining package_set is distributed -- anything can define a 'foo' group by
# setting `node[:package_set][:pkgs][:foo]`, no need to modify this
# cookbook. Selecting *which* packages to install is however unambiguous -- you
# must expressly add the set 'foo' to your node[:package_set][:install] attribute.
#

#
# Package sets to install. Add or remove as convenience & prudence dictate.
#
default[:package_set][:install]          = %w[ base dev sysadmin ]

# --------------------------------------------------------------------------
#
# Package set definitions: related code assets installable as a group
#

default[:package_set][:pkgs][:base]      = %w[ tree git zip openssl wget curl runit libyaml-dev libxslt1-dev ]
default[:package_set][:gems][:base]      = %w[ bundler rake ]

default[:package_set][:pkgs][:dev]       = %w[ emacs23-nox elinks colordiff ack exuberant-ctags ]
default[:package_set][:gems][:dev]       = %w[
  activesupport activemodel extlib json yajl-ruby awesome_print addressable cheat
  yard jeweler rspec  watchr pry configliere gorillib highline formatador choice rest-client wirble hirb
  ]

default[:package_set][:pkgs][:sysadmin]  = %w[ ifstat htop tree chkconfig sysstat nmap python-software-properties ]
default[:package_set][:gems][:sysadmin]  = %w[]

default[:package_set][:pkgs][:text]      = %w[ libidn11-dev libxml2-dev libxml2-utils libxslt1-dev tidy ]
default[:package_set][:gems][:text]      = %w[ nokogiri erubis i18n ]

default[:package_set][:pkgs][:ec2]       = %w[ s3cmd ec2-ami-tools ec2-api-tools ]
default[:package_set][:gems][:ec2]       = %w[ fog right_aws cluster_chef ]

default[:package_set][:pkgs][:vagrant]   = %w[ ifstat htop tree chkconfig sysstat nmap ]
default[:package_set][:gems][:vagrant]   = %w[ vagrant veewee cluster_chef ]

default[:package_set][:pkgs][:python]    = %w[python-dev python-setuptools pythong-simplejson]

default[:package_set][:pkgs][:datatools] = %w[
  r-base r-base-dev x11-apps eog texlive-common texlive-binaries dvipng
  ghostscript latex libfreetype6 python-gtk2 python-gtk2-dev python-wxgtk2.8
]

ruby_mode = (node[:languages][:ruby][:version] =~ /^1.9/ ? "ruby1.9.1-elisp" : "ruby") # rescue nil
default[:package_set][:pkgs][:emacs]     = [ "emacs23-nox", "emacs23-el", "python-mode", ruby_mode, "org-mode" ].compact
