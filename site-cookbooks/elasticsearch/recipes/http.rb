include_recipe "nginx"

template File.join(node[:nginx][:dir], "sites-available", "elasticsearch.conf") do
  source "elasticsearch.nginx.conf.erb"
  action :create
end

nginx_site "elasticsearch.conf" do
  action :enable
end


load_balancer   node[:elasticsearch][:load_balancer] if node[:elasticsearch][:load_balancer]
provide_service("#{node[:elasticsearch][:cluster_name]}-http_esnode")
