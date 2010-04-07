# #
# # Reformat Local Scratch disks to xfs
# #
# node[:hadoop][:local_disks].each do |mount_point, dev|
#   Chef::Log.info ['reformat local pre', mount_point, dev].inspect
#   Chef::Log.info [node[:filesystem].to_hash, File.exists?(dev) ].inspect
#   execute 'reformat_scratch_disks_wiping_out_everything_seriously_be_careful_dood' do
#     Chef::Log.info ['reformat local doit', mount_point, dev].inspect
#     Chef::Log.info [node[:filesystem].to_hash, File.exists?(dev) ].inspect
#     command %Q{ mkfs.xfs -f #{dev} }
#     only_if{ File.exists?(dev)  }
#     not_if{  node[:filesystem][dev] && node[:filesystem][dev][:fs_type] == 'xfs' }
#   end
# end
