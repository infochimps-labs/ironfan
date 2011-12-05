action :create do
  new_resource.assume_defaults!

  directory new_resource.dashboard_dir do
    owner       "root"
    group       "root"
    mode        "0755"
    action      :create
    recursive   true
  end

  template ::File.join(new_resource.dashboard_dir, "#{new_resource.template_name}.html") do
    source      "dashpot-#{new_resource.template_name}.html.erb"
    owner       "root"
    group       "root"
    mode        "0644"
    cookbook    new_resource.cookbook  if new_resource.cookbook
    # unless explicit variables, use the node variables matching the given name:
    # so, `dashpot_dashboard(:redis){ ... }` gives node[:redis][:home_dir]
    # as @home_dir, node[:redis][:server][:port] as @server[:port], and so on.
    variables   new_resource.variables ? new_resource.variables : node[new_resource.name]
    action      :create
  end
end
