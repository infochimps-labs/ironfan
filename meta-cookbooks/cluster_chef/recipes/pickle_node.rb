
#
# pickle your node metadata to a file -- useful for teleporting back home to a VM
#

file "#{node[:cluster_chef][:conf_dir]}/chef_node-#{node.name}.json" do
  content       JSON.pretty_generate(node.to_hash)
  action        :create
  owner         'root'
  group         'root'
  mode          "0600" # only readable by root
end
