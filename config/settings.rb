require 'configliere'
Settings.read File.join(ENV['HOME'],'.poolparty','aws'); Settings.resolve!

#
# Build settings for a given cluster_name and role folding together the common
# settings for everything, common settings for cluster, and the role itself.
#
def settings_for_node cluster_name, cluster_role
  cluster_name = cluster_name.to_sym
  cluster_role = cluster_role.to_sym
  ( { :attributes => { :run_list => [] } }            ).deep_merge(
    Settings[:pools][:common]                    ||{ }).deep_merge(
    Settings[:pools][cluster_name][:common]      ||{ }).deep_merge(
    Settings[:pools][cluster_name][cluster_role] ||{ })
end
