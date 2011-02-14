directory "/usr/local/src" do
  mode      '0775'
  owner     'root'
  group     'admin'
  action    :create
  recursive true
end

redis_install_url = node[:redis][:install_url]
redis_install_pkg = File.basename(redis_install_url)
redis_install_dir = redis_install_pkg.gsub(%r{(?:-bin)?\.tar\.gz}, '')

remote_file "/usr/local/src/"+redis_install_pkg do
  source    redis_install_url
  mode      "0644"
  action :create
end


bash 'install redis from tarball' do
  user         'root'
  cwd          '/usr/local/share'
  code <<EOF
  tar xzf /usr/local/src/#{redis_install_pkg}
  cd  #{redis_install_dir}
  make
  true
EOF
  not_if{ File.directory?("/usr/local/share/#{redis_install_dir}") && File.exists?("/usr/local/share/#{redis_install_dir}/redis-server") }
end

link "/usr/local/share/redis" do
  to "/usr/local/share/"+redis_install_dir
  action :create
end

%w[redis-benchmark redis-cli redis-server
].each do |redis_cmd|
  link "/usr/local/bin/#{redis_cmd}" do
    to "/usr/local/share/redis/#{redis_cmd}"
    action :create
  end
end
