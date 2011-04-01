#
# Enable JNA support for Cassandra
#

# XXX: Only supports Ubuntu x86_64
if node[:platform].downcase == "ubuntu" && node[:kernel][:machine] == "x86_64"
  bash "install_libjna-java" do
    dlfile = "libjna-java_amd64.deb"
    user "root"
    cwd "/tmp"
    code <<-EOCODE
wget -q -O #{dlfile} #{node[:cassandra][:jna_deb_amd64_url]} && \
  dpkg -i #{dlfile}
EOCODE
    not_if "dpkg -s libjna-java | egrep '^Status: .* installed' > /dev/null"
  end

  # Link into our cassandra directory
  link "#{node[:cassandra][:cassandra_home]}/lib/jna.jar" do
    to "/usr/share/java/jna.jar"
    notifies :restart, resources(:service => "cassandra")
  end
else
  Chef::Log.warn("JNA cookbook not supported on this platform")
end
