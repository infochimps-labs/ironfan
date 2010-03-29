users    Mash.new unless attribute?("users")
groups   Mash.new unless attribute?("groups")
ssh_keys Mash.new unless attribute?("ssh_keys")
roles    Mash.new unless attribute?("roles")

# roles[:chef]   = {:groups => [:admin],       :sudo_groups => [:admin]}
# roles[:app]    = {:groups => [:admin, :app], :sudo_groups => [:admin]}

# ssh_keys[:jose]      = "ssh-dss keydata"
# ssh_keys[:francisco] = "ssh-rsa keydata"
