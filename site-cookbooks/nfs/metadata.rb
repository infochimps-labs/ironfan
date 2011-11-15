maintainer       "37signals"
maintainer_email "sysadmins@37signals.com"
license          ""
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Configures NFS"

depends          "provides_service"

recipe           "nfs::client",                        "NFS client: uses provides_service to discover its server, and mounts the corresponding NFS directory"
recipe           "nfs::default",                       "Base configuration for nfs"
recipe           "nfs::server",                        "NFS server: exports directories via NFS; announces using provides_service."

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "nfs/exports",
  :display_name          => "NFS Exports",
  :description           => "Describes the volumes to export. Supply a list of pairs: <path-to-export, hash-of-NFS-options>. For example, \n   default[:nfs][:exports] = [[ '/home', { :nfs_options => '*.internal(rw,no_root_squash,no_subtree_check)' }]]",
  :default               => {}

attribute "nfs/mounts",
  :display_name          => "NFS Mounts",
  :description           => "The foreign volumes to mount. Uses provides_service to find the NFS server for that volume. Supply a list of pairs: <path-to-export, hash-of-NFS-options>.",
  :type                  => "array",
  :default               => [["/home", {:owner=>"root", :remote_path=>"/home"}]]
