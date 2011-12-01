
#
# pickle your node metadata to a file -- useful for teleporting back home to a VM
#

file "#{node[:cluster_chef][:conf_dir]}/chef_node-#{node.name}.json" do
  hsh = Mash.new(node.to_hash)
  %w[ role recipe roles recipes keys ohai_time uptime_seconds uptime idletime_seconds idletime counters run_away ].each{|key| hsh.delete(key)}
  hsh[:provides_service].each{|k,v| v.delete("timestamp") } # ; hsh[:provides_service][k] = v }
  hsh[:kernel][:modules].each{|nm,mod| mod.delete(:refcount) }
  # hsh[:network][:interfaces].each{|nm,i| Chef::Log.info(i) ; next unless i[:rx] ; i[:rx].delete(:packets); i[:rx].delete(:bytes); }
  content       JSON.pretty_generate(hsh)
  action        :create
  owner         'root'
  group         'root'
  mode          "0600" # only readable by root
end
