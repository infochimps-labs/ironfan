class_from_file ::File.expand_path('package.rb', ::File.dirname(__FILE__))

action :build do
  action_configure
  bash "build #{new_resource.name} with ant" do
    user        new_resource.user
    cwd         new_resource.install_dir
    code        "ant"
    environment('JAVA_HOME' => new_resource.java_home) if new_resource.java_home
  end
end
