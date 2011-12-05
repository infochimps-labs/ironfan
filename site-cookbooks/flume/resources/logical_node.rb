
actions :spawn, :unmap, :config

attribute :name,          :name_attribute => true
attribute :physical_node, :kind_of => String    #, :default => node[:fqdn]
attribute :flow,          :default => "default-flow"
attribute :source,        :kind_of => String
attribute :sink,          :kind_of => String
attribute :flume_master,  :kind_of => String    #, default => discover_all(:flume, :master).map(&:private_ip).sort
attribute :spawned,       :default => false

# Commented out defaults require chef 0.9.14 or better to work.
