# ---------------------------------------------------------------------------
#
# Install plugins
#

directory "#{node[:elasticsearch][:install_dir]}/plugins" do
  owner         "root"
  group         "root"
  mode          0755
end

["cloud-aws"].each do |plugin|
  bash "install #{plugin} plugin for elasticsearch" do
    user          "root"
    cwd           "#{node[:elasticsearch][:install_dir]}"
    code          "./bin/plugin -install #{plugin}"
    not_if{ File.exist?("#{node[:elasticsearch][:install_dir]}/plugins/#{plugin}")  }
  end
end
