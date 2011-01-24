
# cluster 'all' do
#   role_implication "hadoop_namenode" do
#     cloud.security_group 'hadoop_namenode' do
#       authorize_port_range 80..80
#     end
#   end
#
#   role_implication "nfs_server" do
#     cloud.security_group "nfs_server" do
#       authorize_group "nfs_client"
#     end
#   end
#
#   role_implication "nfs_client" do
#     cloud.security_group "nfs_client"
#   end
#
#   role_implication "ssh" do
#     cloud.security_group 'ssh' do
#       authorize_port_range 22..22
#     end
#   end
#
#   role_implication "chef_server" do
#     cloud.security_group "chef_server" do
#       authorize_port_range 4000..4000  # chef-server-api
#       authorize_port_range 4040..4040  # chef-server-webui
#     end
#   end
# end
