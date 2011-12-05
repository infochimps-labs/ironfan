

if platform?(%w[ debian ubuntu ])
  include_recipe 'tuning::ubuntu'
end
