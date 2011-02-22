require 'shellwords'



def get_config(name,master)
  conf = `/usr/lib/flume/bin/flume shell -c #{master} -e getconfigs | grep #{name}`
  result = conf.strip.split(/\s*\t\s*/).map{|config| config.gsub(/\s+/,' ') } rescue ["","","",""]
  # name flow source sink
end

# This is an imperfect way to determine if the node is mapped
def get_status(name,master)
  status = `/usr/lib/flume/bin/flume shell -c #{master} -e getconfigs | grep #{name}`
  if !status or status.empty? or status ~= /DECOMISSIONED/
    return :unmapped
  else
    return :mapped
  end
end
  
action :config do
  name,flow,source,sink = get_config( new_resource.name, new_resource.flume_master )
  my_name, my_flow, my_source, my_sink = 
    [ new_resource.name, new_resource.flow, new_resource.source, new_resource.sink ].map{ |config| config.gsub(/\s+/,' ' ) }

  if (my_flow != flow or my_source != source or my_sink != sink)  
    execute "configure logical node" do
      escaped_command = Shellwords.escape "exec config '#{new_resource.name}' '#{new_resource.flow}' '#{new_resource.source}' '#{new_resource.sink}'"    
      command "flume shell -c #{new_resource.flume_master} -e #{escaped_command}"
    end
    new_resource.updated_by_last_action(true)
  end

end

action :spawn do
  if get_status( new_resource.name, new_resource.flume_master ) != :mapped
    execute "spawn logical node" do
      escaped_command = Shellwords.escape "exec spawn '#{new_resource.physical_node}' '#{new_resource.name}'"    
      command "flume shell -c #{new_resource.flume_master} -e #{escaped_command}"
    end
    new_resource.updated_by_last_action(true)
  end
end

action :unmap do
  if get_status( new_resource.name, new_resource.flume_master ) != :mapped
    execute "unmap logical node" do
      escaped_command = Shellwords.escape "exec unmap '#{new_resource.physical_node}' '#{new_resource.name}'"    
      command "flume shell -c #{new_resource.flume_master} -e #{escaped_command}"
    end
    new_resource.updated_by_last_action(true)
  end
end

  
