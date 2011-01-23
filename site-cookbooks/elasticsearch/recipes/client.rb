
%w[libcurl4-openssl-dev wamerican-large].each do |pkg|
  package pkg
end

%w[rubberband].each do |gem_pkg|
  gem_package gem_pkg
end
