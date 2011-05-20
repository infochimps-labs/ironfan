# -*- ruby -*-

def run_spec(file)
  unless File.exist?(file)
    puts "#{file} does not exist"
    return
  end

  puts   "Running #{file}"
  system "bundle exec rspec #{file}"
  puts
end

watch("spec/.*/*_spec\.rb") do |match|
  run_spec match[0]
end

watch("lib/(.*)\.rb") do |match|
  run_spec %{spec/#{match[1]}_spec.rb}
end
