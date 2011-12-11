maintainer       "37signals"
maintainer_email "sysadmins@37signals.com"
license          ""
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "NFS: network shared filesystem"

depends          "metachef"

recipe           "nfs::client",                        "NFS client: uses metachef to discover its server, and mounts the corresponding NFS directory"
recipe           "nfs::default",                       "Base configuration for nfs"
recipe           "nfs::server",                        "NFS server: exports directories via NFS; announces using metachef."

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "nfs/exports",
  :display_name          => "NFS Exports",
  :description           => "Describes the volumes to export. Supply a list of pairs: <path-to-export, hash-of-NFS-options>. For example, \n   default[:nfs][:exports] = [[ '/home', { :nfs_options => '*.internal(rw,no_root_squash,no_subtree_check)' }]]",
  :default               => ""

attribute "nfs/mounts",
  :display_name          => "NFS Mounts",
  :description           => "The foreign volumes to mount. Uses metachef discovery to find the NFS server for that volume. Supply a list of pairs: <path-to-export, hash-of-NFS-options>.",
  :type                  => "array",
  :default               => [["/home", {:owner=>"root", :remote_path=>"/home"}]]

attribute "firewall/port_scan/portmap",
  :display_name          => "",
  :description           => "",
  :type                  => "hash",
  :default               => {:port=>111, :window=>20, :max_conns=>15}

attribute "firewall/port_scan/nfsd",
  :display_name          => "",
  :description           => "",
  :type                  => "hash",
  :default               => {:port=>2049, :window=>20, :max_conns=>15}

attribute "firewall/port_scan/mountd",
  :display_name          => "",
  :description           => "",
  :type                  => "hash",
  :default               => {:port=>45560, :window=>20, :max_conns=>15}

attribute "firewall/port_scan/statd",
  :display_name          => "",
  :description           => "",
  :type                  => "hash",
  :default               => {:port=>56785, :window=>20, :max_conns=>15}
