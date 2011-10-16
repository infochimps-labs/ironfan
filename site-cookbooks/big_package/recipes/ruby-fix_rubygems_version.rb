
Chef::Log.debug [ node[:ruby] ].inspect + "\n\n!!!\n\n"

rubygems_target_version = "1.6.2"
bash "update rubygems to = #{rubygems_target_version}" do
  code %Q{
    gem install --no-rdoc --no-ri rubygems-update --version=#{rubygems_target_version}
    update_rubygems --version=#{rubygems_target_version}
  }
  not_if{ `gem --version`.chomp >= rubygems_target_version }
end

cookbook_file "/tmp/fuck_you_rubygems.diff" do
  owner   "root"
  group   "root"
  mode    "0644"
  source  "fuck_you_rubygems.diff"
  action  :create
end
