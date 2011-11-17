
# Get the archive key for cloudera package repo
execute "curl -s http://archive.cloudera.com/debian/archive.key | apt-key add -" do
  not_if "apt-key export 'Cloudera Apt Repository' | grep 'BEGIN PGP PUBLIC KEY'"
  notifies :run, "execute[apt-get update]"
end

# Add cloudera package repo
apt_repository 'cloudera' do
  uri             'http://archive.cloudera.com/debian'
  distro        = node[:apt][:cloudera][:force_distro] || node[:lsb][:codename]
  distribution    "#{distro}-#{node[:hadoop][:cdh_version]}"
  components      ['contrib']
  key             "http://archive.cloudera.com/debian/archive.key"
  action          :add
end
