# Packages required for further chef config

%w[ right_aws broham ].each do |pkg|
  gem_package(pkg){ action :install }
end

