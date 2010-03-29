users    Mash.new unless attribute?("users")
groups   Mash.new unless attribute?("groups")
ssh_keys Mash.new unless attribute?("ssh_keys")
roles    Mash.new unless attribute?("roles")

groups[:app]   = {:gid => 5000}
groups[:site]  = {:gid => 6000}
groups[:admin] = {:gid => 7000}

roles[:chef]   = {:groups => [:admin],       :sudo_groups => [:admin]}
roles[:app]    = {:groups => [:admin, :app], :sudo_groups => [:admin]}

# passwords must be in shadow password format with a salt. To generate: openssl passwd -1
users[:jose]      = {:password => "shadowpass", :comment => "Flip Kromer",   :uid => 4001, :group => :admin}
users[:francisco] = {:password => "shadowpass", :comment => "Dhruv Bansal",  :uid => 4002, :group => :admin}

ssh_keys[:jose]      = "ssh-dss keydata"
ssh_keys[:francisco] = "ssh-rsa keydata"
