
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
#       selects     :single
#     end
#
# This has an explicit partial path,
#
# @example
#
#     volume_dirs("hadoop.dfs_name") do
#       type        :persistent
#       selects     :all
#       path        'hadoop/hdfs/data'
#       owner       'hdfs'
#       group       'hadoop'    
#       mode        "0700"
#     end
#
define(:volume_dirs,
  :aspect    => nil,         # eg 'log', 'data', etc.
  :selects   => nil,         # :all creates ??_log_dirs, an array of one or more for the matching volume set; :single creates ??_log_dir, from the first in the matching volume set
  :type      => :persistent, # one of `:persistent` or `:scratch`
  :path      => nil,         # default: "#{name}/#{aspect}" -- eg "mysql/log" or "redis/data". NOTE: node value is present, it is used as the full path and this is ignored.
  #
  :owner     => nil,         # passed on to `directory` if set
  :group     => nil,         # passed on to `directory` if set
  :mode      => nil          # passed on to `directory` if set
  ) do

  name      = params[:name]
  component = params[:component]
  aspect    = params[:aspect]
  if    name.to_s =~ /^\w+\.\w+$/
    name, component, aspect = name.split(".", 3).map(&:to_sym)
  elsif name.to_s =~ /^\w+\.\w+$/
    name, aspect            = name.split(".", 2).map(&:to_sym)
  end
  raise "Please provide a system and an aspect (eg 'redis.log', or 'mysql.data')" unless aspect
  raise "Please select either :all or :single" unless ['all', 'first', nil].include?(params[:selects].to_s)

  aspect_attr = (selects == :all) ? "#{name}_dirs" : "#{name}_dir"
  
  params[:selects] ||= :all
  params[:user]    ||= scoped_default(name, component, :user, :required )
  params[:group]   ||= scoped_default(name, component, :group) || params[:group]

  #
  # Once we've chosen a path, we need to use it forever.
  #
  paths = Array( scoped_default(name, component, aspect_attr) ).compact
  if paths.empty?
    sub_path = params[:path] || [name, component, aspect].compact.join('/')

    volumes = mounted_volumes_tagged(params[:type])
    volumes = [volumes.first] if (selects == :single)
    paths  = volumes.map{|vol, vol_info| ::File.expand_path(sub_path, vol_info[:mount_point]) }
  end

  paths.each do |path|
    directory(path) do
      owner     params[:owner] if owner
      group     params[:group] if group
      mode      params[:mode ] if params[:mode ] 
      recursive :true
    end
  end

  #
  # Set the node attribute to the actual determined value
  #
  # eg `volume_dirs('hadoop.log')` sets
  #
  #     node[:hadoop][:log_dirs] = ["/ebs1/hadoop/log", "/ebs2/hadoop/log"]
  #
  # and volume_dirs('redis.data'){ selects(:single) } sets
  #
  #     node[:redis][:data_dir] = "/ebs1/redis/data"
  #
  if component
    node[name][component][aspect_attr] = (selects == :all) ? actual_paths : actual_paths.first 
  else
    node[name][aspect_attr]            = (selects == :all) ? actual_paths : actual_paths.first
  end
end

# Look for (in order)
#
# * the set of paths memoized from earlier (or defined explicitly)
# * volumes tagged 'foo-xx'
# * volumes tagged 'foo-scratch'
# * volumes tagged 'foo'
# * volumes tagged 'scratch'
# * ['/']
#
# If even one volume matches, nothing else is pulled in.
#
# A volume may get used, even if it doesn't announce.
#
