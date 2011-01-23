nfs Mash.new unless attribute?(:nfs)
nfs[:exports] = Mash.new unless nfs.has_key?(:exports)

nfs[:mounts] = [
  ['/home', { :owner => 'root', :remote_path => "/home" } ],
]
