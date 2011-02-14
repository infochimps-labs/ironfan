maintainer       "Infochimps, Inc."
maintainer_email "info@infochimps.com"
license          "Apache 2.0"
description      "Installs and configures the R stats analysis language"
version          "0.1"
depends          "apt", ">> 0.9"
recipe           "Rstats", "Installs the base R package, a ruby interface, and some basic R packages."

#start with just the .deb, perhaps switch to stack installer and/or .rpm
%w{ debian ubuntu }.each do |os|
  supports os
end
