# -*- ruby -*-

def run_spec(file)
  unless File.exist?(file)
    Watchr.debug "#{file} does not exist"
    return
  end

  Watchr.debug "Running #{file}"
  system       "rspec #{file}"
end

watch("spec/.*_spec\.rb") do |match|
  run_spec match[0]
end

watch("libraries/(.*)\.rb") do |match|
  file = %{spec/#{match[1]}_spec.rb}
  run_spec file if File.exists?(file)
end
