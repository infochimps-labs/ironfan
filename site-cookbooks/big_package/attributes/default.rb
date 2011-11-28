default[:pkg_sets][:install]          = %w[ base dev sysadmin ]

default[:pkg_sets][:pkgs][:base]      = %w[ tree git zip openssl ]
default[:pkg_sets][:gems][:base]      = %w[ bundler rake ]

default[:pkg_sets][:pkgs][:dev]       = %w[ emacs23-nox elinks colordiff ack exuberant-ctags ]
default[:pkg_sets][:gems][:dev]       = %w[
  activesupport activemodel extlib json yajl-ruby awesome_print addressable cheat
  yard jeweler rspec  watchr pry configliere gorillib highline formatador choice rest-client wirble hirb ]

default[:pkg_sets][:pkgs][:sysadmin]  = %w[ ifstat atop htop tree chkconfig sysstat htop nmap ]
default[:pkg_sets][:gems][:sysadmin]  = %w[]

default[:pkg_sets][:pkgs][:text]      = %w[ libidn11-dev libxml2-dev libxml2-utils libxslt1-dev tidy ]
default[:pkg_sets][:gems][:text]      = %w[ nokogiri erubis i18n ]

default[:pkg_sets][:pkgs][:ec2]       = %w[ s3cmd ec2-ami-tools ec2-api-tools ]
default[:pkg_sets][:gems][:ec2]       = %w[ fog right_aws ]

default[:pkg_sets][:pkgs][:vagrant]   = %w[ ifstat htop tree chkconfig sysstat htop nmap ]
default[:pkg_sets][:gems][:vagrant]   = %w[ vagrant ]

default[:pkg_sets][:pkgs][:python]    = %w[python-dev python-setuptools pythong-simplejson]

default[:pkg_sets][:pkgs][:datatools] = %w[
  r-base r-base-dev x11-apps eog texlive-common texlive-binaries dvipng
  ghostscript latex libfreetype6 python-gtk2 python-gtk2-dev python-wxgtk2.8
]


ruby_mode = (node[:languages][:ruby][:version] =~ /^1.9/ ? "ruby1.9.1-elisp" : "ruby") # rescue nil
default[:pkg_sets][:pkgs][:emacs]     = [ "emacs23-nox", "emacs23-el", "python-mode", ruby_mode, "org-mode" ].compact
