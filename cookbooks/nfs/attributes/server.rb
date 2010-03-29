nfs Mash.new unless attribute?(:nfs)
nfs[:exports] = Mash.new unless nfs.has_key?(:exports)
