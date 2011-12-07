# -*- ruby -*-

def run_spec(file)
  unless File.exist?(file)
    puts "#{file} does not exist"
    return
  end

  puts   "Running #{file}"
  system "rspec #{file}"
  puts
end

watch("spec/.*/*_spec\.rb") do |match|
  run_spec match[0]
end

watch("lib/(.*)\.rb") do |match|
  file = %{spec/#{match[1]}_spec.rb}
  run_spec file if File.exists?(file)
end

# watch('lib/cluster_chef/cookbook_munger\.rb') do |match|
#   system match[0]
# end
#
# watch('lib/cluster_chef/cookbook_munger/.*\.erb') do |match|
#   system 'lib/cluster_chef/cookbook_munger.rb'
# end
