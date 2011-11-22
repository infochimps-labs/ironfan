
# Say the :perm volumes are `/ebs1` and `/ebs2`. The following will
#
# * creates directories `/ebs1/cassandra` and `/ebs1/cassandra`, owned by root
# * creates directories `/ebs1/cassandra/data` and `/ebs1/cassandra/data`, with user/group taken from node[:cassandra] and default mode 0755.
# * sets node[:cassandra][:data_dirs] to `['/ebs1/cassandra/data', '/ebs1/cassandra/data']`
#
# @example
#
#     volume_dirs("cassandra.data") do
#       type        :persistent
#     end
#
# This has an implicit path of "#{vol}/hadoop/log". Everything else is described:
#
# @example
#
#     volume_dirs("hadoop.log") do
#       type        :scratch
#       owner       'hdfs'
#       group       'hadoop'
#       mode        "0775"
#       selects     :first
#     end
#
# This has an explicit partial path,
#
# @example
#
#     volume_dirs("hadoop.dfs_name") do
#       type        :persistent
#       path        'hadoop/hdfs/data'
#       owner       'hdfs'
#       group       'hadoop'    
#       mode        "0700"
#       selects     :all
#     end
#
define(:scratch_volume_dirs
  ) do

  name = params[:name]


  # Look for (in order)
  # * volumes tagged 'foo-xx'
  # * volumes tagged 'foo-scratch'
  # * volumes tagged 'foo'
  # * volumes tagged 'scratch'
  # * ['/']
  #
  # If even one volume matches, nothing else is pulled in.
  #
  # A volume may get used, even if it doesn't announce:
  #
  volumes = mounted_volumes_tagged(params[:type])

  attr = ( (params[:selects] == :all) ? "#{name}_dirs" : "#{name_dir}" ).to_s
  
  volumes.each do |vol, vol_info|

    directory( ::File.expand_path(params[:path], vol_info[:mount_point]) ) do
      owner params[:owner] if params[:owner] 
      group params[:group] if params[:group] 
      mode  params[:mode ] if params[:mode ] 
      recursive :true
    end

  end
  
end
