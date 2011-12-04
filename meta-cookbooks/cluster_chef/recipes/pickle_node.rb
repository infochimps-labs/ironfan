
#
# pickle your node metadata to a file -- useful for teleporting back home to a VM
#

file "#{node[:cluster_chef][:conf_dir]}/chef_node-#{node.name}.json" do
  hsh = Mash.new(node.to_hash)
  # role recipe roles recipes
  %w[ keys ohai_time uptime_seconds uptime idletime_seconds idletime counters run_away ].each{|key| hsh.delete(key)}
  hsh[:provides_service].each{|k,v| v.delete("timestamp") } # ; hsh[:provides_service][k] = v }
  hsh[:kernel][:modules].each{|nm,mod| mod.delete(:refcount) }
  # hsh[:network][:interfaces].each{|nm,i| Chef::Log.info(i) ; next unless i[:rx] ; i[:rx].delete(:packets); i[:rx].delete(:bytes); }
  content       JSON.pretty_generate(hsh)
  action        :create
  owner         'root'
  group         'root'
  mode          "0600" # only readable by root
end

require 'set'

file "#{node[:cluster_chef][:conf_dir]}/chef_resources-#{node.name}.json" do
  resource_clxn = Chef::ResourceCollection.new
  run_context.resource_collection.each do |r|
    next if r.class.to_s == 'Chef::Resource::NodeMetadata'
    r = r.dup
    r.instance_eval do
      content('')   if respond_to?(:content)
      variables({}) if respond_to?(:variables)
      remove_instance_variable('@options') rescue nil
      params.delete(:options) if respond_to?(:params)
      # if respond_to?(:options)
      #   begin ; options({})  ; rescue options('') ; end
      # end
      @delayed_notifications = []
      @immediate_notifications = []
    end
    if r.to_json.length > 1400
      puts r.to_json
    end
    resource_clxn << r
  end
  content       resource_clxn.to_json(JSON::PRETTY_STATE_PROTOTYPE)+"\n"
  action        :create
  owner         'root'
  group         'root'
  mode          "0600" # only readable by root
end

# require 'pry'
# binding.pry


# rr = run_context.resource_collection.select{|r| r.is_a?(Chef::Resource::File) }.map(&:dup).each{|r| r.content '' }
