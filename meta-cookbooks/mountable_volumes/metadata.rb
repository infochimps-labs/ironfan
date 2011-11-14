maintainer       "Philip (flip) Kromer, infochimps.com"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"


description       %Q{Mounts volumes  as directed by node metadata. Can attach external cloud drives, such as ebs volumes.}
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.1"

depends           "aws"
depends           "xfs"
