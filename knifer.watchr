# -*- ruby -*-

COOKBOOK_PATHS = %w[cookbooks meta-cookbooks site-cookbooks] unless defined?(COOKBOOK_PATHS) 
ROLES_PATH     = 'roles'                                     unless defined?(ROLES_PATH) 

def upload_cookbook(cookbook)
  puts   "uploading cookbook #{cookbook}"
  system "knife cookbook upload '#{cookbook}'"
  puts
end

def upload_role(role)
  puts   "uploading role file #{role}"
  system "knife role from file '#{role}'"
  puts
end

COOKBOOK_PATHS.each do |cookbook_path|
  watch("#{cookbook_path}/(.+?)/.*") do |match|
    unless File.directory?(match[0])
      puts "cookbook file #{match[0]} changed"
      upload_cookbook(match[1])
    end
  end
end

watch("#{ROLES_PATH}/.*\.rb") do |match|
  upload_role(match[0])
end 

# p Dir["#{ROLES_PATH}/*.rb"]
# p Dir["#{COOKBOOK_PATHS.first}/*"]
puts "watchr #{__FILE__} loaded"
