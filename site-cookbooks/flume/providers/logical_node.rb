require 'shellwords'


def get_config(name,master)
  conf = `/usr/lib/flume/bin/flume shell -c #{master} -e getconfigs | grep #{name}`
  result = conf.strip.split(/\s*\t\s*/).map{|config| config.gsub(/\s+/,' ') } rescue ["","","",""]
  # name flow source sink
end


def get_mapping(name,master)
  map = {}
  mapping = `/usr/lib/flume/bin/flume shell -c #{master} -e getmappings`
  mapping.split(/\n/).each do |s|
    if s =~ /(\S+)\s+-->\s*\[(.*)\]/
      physical = $1
      logical  = $2.split(/,/)
      logical.each {|l| map[l.strip] = physical } 
    end
  end
  map[name.strip]
end
  
action :config do
  # figure out how this logical node is currently configured
  name,flow,source,sink = get_config( new_resource.name, new_resource.flume_master )
  my_name, my_flow, my_source, my_sink = 
    [ new_resource.name, new_resource.flow, new_resource.source, new_resource.sink ].map{ |config| config.gsub(/\s+/,' ' ) }

  # only do a config if the configuration is different from the target
  if (my_flow != flow or my_source != source or my_sink != sink)  
    execute "configure logical node" do
      escaped_command = Shellwords.escape "exec config '#{new_resource.name}' '#{new_resource.flow}' '#{new_resource.source}' '#{new_resource.sink}'"    
      command "flume shell -c #{new_resource.flume_master} -e #{escaped_command} ; true"
    end
    new_resource.updated_by_last_action(true)
  end

end

action :spawn do
  physical = get_mapping( new_resource.name, new_resource.flume_master )
  Chef::Log.info "Logical node #{new_resource.name} -> #{physical.to_s}. Should be #{new_resource.physical_node }"
  if( physical && physical != new_resource.physical_node )
    execute "unmapping logical node #{new_resource.name}" do
      escaped_command = Shellwords.escape "exec unmap '#{physical}' '#{new_resource.name}'"    
      command "flume shell -c #{new_resource.flume_master} -e #{escaped_command} ; true"
    end
    new_resource.updated_by_last_action(true)
  end
  
  if ( physical != new_resource.physical_node )
    execute "spawn logical node" do
      escaped_command = Shellwords.escape "exec spawn '#{new_resource.physical_node}' '#{new_resource.name}'"    
      command "flume shell -c #{new_resource.flume_master} -e #{escaped_command} ; true"
    end
    new_resource.updated_by_last_action(true)
  end
end

action :unmap do
  physical = get_mapping( new_resource.name, new_resource.flume_master ) 
  if physical == new_resource.physical_node
    execute "unmap logical node" do
      escaped_command = Shellwords.escape "exec unmap '#{new_resource.physical_node}' '#{new_resource.name}'"    
      command "flume shell -c #{new_resource.flume_master} -e #{escaped_command}"
    end
    new_resource.updated_by_last_action(true)
  end
end

  
