# -*- ruby -*-

def run_spec(file)
  file = File.expand_path(file, File.dirname(__FILE__))
  unless File.exist?(file)
    Watchr.debug "#{file} does not exist"
    return
  end

  Watchr.debug "Running #{file}"
  system       "rspec #{file}"
end

watch("spec/.*_spec\.rb") do |match|
  run_spec(match[0])
end

watch("libraries/(.*)\.rb") do |match|
  run_spec(%{spec/#{match[1]}_spec.rb})
end
