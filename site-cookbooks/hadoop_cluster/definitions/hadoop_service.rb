
define(:hadoop_service, :service_name => nil, :package_name => nil) do
  name = params[:name].to_s
  service_name = params[:service_name] || name
  package_name = params[:package_name] || name

  hadoop_package package_name

  # Set up service
  runit_service "hadoop_#{name}" do
    run_state     node[:hadoop][name][:run_state]
    options       Mash.new(:service_name => service_name
      ).merge(node[:hadoop]
      ).merge(node[:hadoop][name])
  end
  kill_old_service("#{node[:hadoop][:handle]}-#{name}") do
    only_if{ File.exists?("/etc/init.d/#{node[:hadoop][:handle]}-#{name}") }
  end

  announce(:hadoop, :name)
end
