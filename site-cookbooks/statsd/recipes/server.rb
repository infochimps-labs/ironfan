include_recipe "statsd::default"

git node[:statsd][:install_dir] do
  repository    node[:statsd][:git_repo]
  reference     "master"
  action        :sync
end

template "#{node[:statsd][:install_dir]}/baseConfig.js" do
  source        "baseConfig.js.erb"
  mode          "0755"
  notifies      :restart, "service[statsd]"
end

runit_service 'statsd' do
end

provide_service ("#{node[:statsd][:cluster_name]}-statsd")
