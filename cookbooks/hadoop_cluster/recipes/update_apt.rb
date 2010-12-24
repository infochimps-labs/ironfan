class Chef::Recipe; include HadoopCluster ; end

#
# Run it for sure
#
execute "apt-get update" do
  action :nothing
end
