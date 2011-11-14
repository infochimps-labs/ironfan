maintainer       "37signals"
maintainer_email "sysadmins@37signals.com"
license          ""
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Configures NFS"

depends          "provides_service"


%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "nfs/exports",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "nfs/mounts",
  :type                  => "array",
  :default               => [["/home", {:owner=>"root", :remote_path=>"/home"}]],
  :display_name          => "",
  :description           => ""
