gem_package "whenever"

directory '/etc/whenever' do
  action :create
  group 'admin'
  mode 0775
end




