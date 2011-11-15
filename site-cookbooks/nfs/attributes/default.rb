default[:nfs][:exports] = Mash.new

default[:nfs][:mounts] = [
  ['/home', { :owner => 'root', :remote_path => "/home" } ],
]
