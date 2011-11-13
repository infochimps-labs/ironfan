package "sun-java6-jdk"
package "sun-java6-bin"
package "sun-java6-jre"

bash 'build piggybank' do
  user        'root'
  cwd         "#{node[:pig][:home_dir]}/contrib/piggybank/java"
  environment 'JAVA_HOME' => node[:pig][:java_home]
  code        'ant'
  not_if{ File.exists?("#{node[:pig][:home_dir]}/contrib/piggybank/java/piggybank.jar") }
end
