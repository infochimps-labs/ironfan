execute "Kill dhclient" do
  command "kill #{File.read("/var/run/dhclient.eth0.pid").chomp}"
  only_if "pgrep dhclient"
end

execute "Install resolv.conf" do
  command "cp /etc/ec2/resolv.conf /etc/resolv.conf"
end

bootstrap_fqdn = "#{node[:assigned_hostname]}.#{node[:assigned_domain]}"

bash "Add hosts entry for current node" do
  code "echo '#{node[:ipaddress]} #{bootstrap_fqdn}' >> /etc/hosts"
  not_if "grep '#{node[:ipaddress]} #{bootstrap_fqdn}' /etc/hosts"
end

bash "Set domain name" do
  code "echo #{node[:assigned_domain]} /etc/domainname"
  not_if "grep #{node[:assigned_domain]} /etc/domainname"
end

bash "Set hostname" do
  code "echo #{bootstrap_fqdn} > /etc/hostname"
  not_if "grep #{bootstrap_fqdn} /etc/hostname"
end

bash "Set mailname for postfix" do
  code "echo #{bootstrap_fqdn} > /etc/mailname"
  not_if "grep #{node[:assigned_hostname]} /etc/mailname"
end

execute "Set hostname" do
  command "/etc/init.d/hostname.sh"
  only_if { `hostname -f` != bootstrap_fqdn }
end