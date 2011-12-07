#
# Discover volumes of the requested character, create directories on the first
# or on all.
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
#       type        :local
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
  :type      => :persistent, # one of `:persistent` or `:local`
  :path      => nil,         # default: "#{sys}/#{subsys}/#{aspect}" -- eg "mysql/log" or "redis/data". NOTE: if the node attribute is already present, it is used as the full path and this is ignored.
  #
  :owner     => nil,         # passed on to `directory` if set
  :group     => nil,         # passed on to `directory` if set
  :mode      => nil          # passed on to `directory` if set
  ) do

  if    params[:name].to_s =~ /^\w+\.\w+\.\w+$/
    sys, subsys, aspect = params[:name].to_s.split(".", 3).map(&:to_sym)
  elsif params[:name].to_s =~ /^\w+\.\w+$/
    sys,         aspect = params[:name].to_s.split(".", 2).map(&:to_sym)
  else
    raise "Please provide a system and an aspect (eg 'redis.log'), or system.subsystem.aspect (eg 'hadoop.namenode.data'): got #{params[:name]}"
  end
  component = ClusterChef::Component.new(node, sys, subsys)

  params[:selects] ||= :all
  raise "Please select either :all or :single" unless ['all', 'single'].include?(params[:selects].to_s)
  aspect_attr = (params[:selects] == :all) ? "#{aspect}_dirs" : "#{aspect}_dir"

  params[:owner]      ||= component.node_attr(:user, :required)
  params[:group]      ||= component.node_attr(:group) || params[:owner]

  Log.info( [params[:name], params, component.to_hash] )

  #
  # Once we've chosen a path, we need to use it forever.
  #
  paths = Array( component.node_attr(aspect_attr) ).compact
  if paths.empty?
    # default path to "sys/subsys/aspect", eg "graphite/carbon/log"
    sub_path = params[:path] || File.join(*[sys, subsys, aspect].compact.map{|s| s.to_s})
    # look for "graphite.carbon.log", "graphite.log", "log", or fallback
    volumes = volumes_tagged(
      "#{sys}_#{subsys}_#{aspect}", "#{sys}_#{aspect}", params[:type], 'fallback')
    # singularize if :single
    volumes = [volumes.first] if (params[:selects] == :single)
    # slap path on the end of volume roots
    paths  = volumes.map{|vol, vol_info| ::File.expand_path(sub_path, vol_info[:mount_point]) }
  end

  paths.each do |path|
    directory(path) do
      owner     params[:owner] if params[:owner]
      group     params[:group] if params[:group]
      mode      params[:mode ] if params[:mode ]
      action    :create
      recursive true
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
  if subsys
    val = (params[:selects] == :single) ? paths.first : paths
    unless node[sys][subsys][aspect_attr] == val
      Chef::Log.info("setting %-40s to %s" % ["node[#{sys}][#{subsys}][#{aspect_attr}]", paths.inspect])
      node.set[sys][subsys][aspect_attr] = val
      node_changed!
    end
  else
    val = (params[:selects] == :single) ? paths.first : paths
    unless node[sys][aspect_attr] == val
      Chef::Log.info("setting %-40s to %s" % ["node[#{sys}][#{aspect_attr}]", paths.inspect])
      node.set[sys][aspect_attr] = val
      node_changed!
    end
  end
end
