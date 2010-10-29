maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs subversion"
version           "0.8.4"

%w{ redhat centos fedora ubuntu debian }.each do |os|
  supports os
end

# depends "apache2" # argh. This is only needed for the server part. We don't
                    # want that for the hadoop recipes, but maybe you do.

recipe "subversion", "Includes the client recipe."
recipe "subversion::client", "Subversion Client installs subversion and some extra svn libs"
recipe "subversion::server", "Subversion Server (Apache2 mod_dav_svn)"
