actions(
  :create # create dashboard file in "#{dashboard_dir}/#{template_name}.html"
  )

# name of this dashboard
attribute :name,          :name_attribute => true

# location of dashboard snippets, node[:dashpot][:home_dir] by default
attribute :dashboard_dir, :kind_of => String, :default => nil

# use the named template (otherwise the name variable is used).  We'll look for
# a template file named "dashboard_snippet-#{template_name}.html.erb", and put
# it in "#{dashboard_dir}/#{template_name}.html"
attribute :template_name, :kind_of => String, :default => nil

# if not explicitly set, use the node variables matching the given name: so,
# `dashpot_dashboard(:redis){ ... }` gives node[:redis][:home_dir] as
# @home_dir, node[:redis][:server][:port] as @server[:port], and so on.
attribute :variables,     :kind_of => Hash, :default => nil

# override the cookbook to source from
attribute :cookbook,      :kind_of => String, :default => nil

def initialize(*args)
  super
  @action ||= :create
end

def assume_defaults!
  @variables       = Mash.new(variables) # mashify
  @dashboard_dir ||= node[:dashpot][:home_dir]
  @template_name ||= name
end
