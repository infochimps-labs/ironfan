directory "/usr/local/src" do
  mode      '0775'
  owner     'root'
  group     'admin'
  action    :create
  recursive true
end

pig_install_pkg = File.basename(node[:pig][:install_url])
pig_install_dir = pig_install_pkg.gsub(%r{(?:-bin)?\.tar\.gz}, '')

remote_file "/usr/local/src/#{pig_install_pkg}" do
  source    node[:pig][:install_url]
  mode      "0644"
  action :create
end

bash 'install from tarball' do
  user 'root'
  cwd  '/usr/local/share'
  code "tar xzf /usr/local/src/#{pig_install_pkg}"
  not_if{ File.directory?("/usr/local/share/#{pig_install_dir}") }
end

link "/usr/local/share/pig" do
  to "/usr/local/share/#{pig_install_dir}"
  action :create
end

link "/usr/local/bin/pig" do
  to "/usr/local/share/pig/bin/pig"
  action :create
end
