#
# Cookbook Name:: cluster_chef
# Recipe::        burn_ami_prep
#

template "/tmp/burn_ami_prep.sh" do
  owner     "root"
  mode      "0700"
  source    "burn_ami_prep.sh.erb"
end
