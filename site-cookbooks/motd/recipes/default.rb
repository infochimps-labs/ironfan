#
# Cookbook Name:: motd
# Recipe::        default
#

#
# Set the Message of the day (motd) file
#

link '/etc/motd' do
  action :delete
  only_if{ File.symlink?('/etc/motd') }
end

def get_silly
  node_name = node[:node_name]
  case                                     # max length = 20
  when node_name =~ /kong/                      then "BORK BORK BORK"
  when node_name =~ /alphamale/                 then "SERVE SERVE SERVE"
  when node_name =~ /dev\./                     then "STAGE STAGE STAGE"
  when node_name =~ /(gibbon|bonobo|chimpmark)/ then "CRUNCH CRUNCH CRUNCH"
  when node_name =~ /^s\d+\./                   then "SCRAPE SCRAPE SCRAPE"
  when node_name =~ /(clyde|ham|magilla|ogee)/  then "DATA DATA DATA DATA DATA"
  when node_name =~ /(hoolock|bobo|yellowhat)/  then "FIND FIND FIND"
  else                                               "OOK OOK OOK"
  end
end
silliness = get_silly

motd_vars = {
      :silliness          => silliness,
}
motd_vars[:provides_service] = node[:provides_service].keys.map(&:to_s).join(', ') unless node[:provides_service].nil?

template "/etc/motd" do
  owner  "root"
  mode   "0644"
  source "motd.erb"
  variables(motd_vars)
end

# Put the node name in a file for other processes to read easily
template "/etc/node_name" do
  mode 0644
  source "node_name.erb"
  action :create
end
